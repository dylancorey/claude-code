"""Read-only MCP server for the Paychex Flex API.

Credentials come from the environment only:
  PAYCHEX_CLIENT_ID, PAYCHEX_CLIENT_SECRET
  PAYCHEX_BASE_URL (optional, default https://api.paychex.com)

Only GET requests are issued to resource endpoints. Sensitive worker
sub-resources (bank accounts, tax forms, documents, images) are not exposed, and identity/bank fields are stripped from every response are not exposed.
"""
import os
import re
import time
from typing import Any

import httpx
from mcp.server.fastmcp import FastMCP

BASE_URL = os.environ.get("PAYCHEX_BASE_URL", "https://api.paychex.com").rstrip("/")

COMPANY_RESOURCES = {
    "calculationbases", "contacttypes", "customemploymenttypes", "customfields",
    "customfieldscategories", "jobs", "jobsegments", "jobtitles", "laborassignments",
    "locations", "organizations", "paycomponents", "payfrequencies", "payperiods",
    "statetaxes", "workerstatuses", "checks",
}
WORKER_RESOURCES = {
    "assignmentdistributions", "checks", "communications", "compensation",
    "compensation/payrates", "compensation/paystandards", "contacts", "customfields",
    "paycomponents", "status", "timeoff",
}

_ID = re.compile(r"^[A-Za-z0-9_-]+$")
_SENSITIVE = re.compile(r"legalid|taxpayer|ssn|birthdate|accountnumber|routing", re.I)

mcp = FastMCP("paychex")


def _id(value: str) -> str:
    if not _ID.match(value):
        raise ValueError("id must contain only letters, digits, underscore or hyphen")
    return value


def _redact(obj: Any) -> Any:
    """Drop identity and bank fields (SSN/tax ID, birth date, account numbers) from responses."""
    if isinstance(obj, dict):
        return {k: _redact(v) for k, v in obj.items() if not _SENSITIVE.search(k)}
    if isinstance(obj, list):
        return [_redact(v) for v in obj]
    return obj
_token: dict[str, Any] = {"value": None, "expires": 0.0}


def _credentials() -> tuple[str, str]:
    cid = os.environ.get("PAYCHEX_CLIENT_ID")
    secret = os.environ.get("PAYCHEX_CLIENT_SECRET")
    if not cid or not secret:
        raise RuntimeError("PAYCHEX_CLIENT_ID and PAYCHEX_CLIENT_SECRET must be set")
    return cid, secret


async def _bearer(client: httpx.AsyncClient) -> str:
    if _token["value"] and time.time() < _token["expires"] - 60:
        return _token["value"]
    cid, secret = _credentials()
    r = await client.post(
        f"{BASE_URL}/auth/oauth/v2/token",
        data={"grant_type": "client_credentials", "client_id": cid, "client_secret": secret},
    )
    r.raise_for_status()
    body = r.json()
    _token["value"] = body["access_token"]
    _token["expires"] = time.time() + float(body.get("expires_in", 3600))
    return _token["value"]


async def _get(path: str, params: dict[str, Any] | None = None) -> Any:
    clean = {k: v for k, v in (params or {}).items() if v is not None}
    async with httpx.AsyncClient(timeout=30) as client:
        token = await _bearer(client)
        r = await client.get(
            f"{BASE_URL}{path}",
            params=clean,
            headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
        )
        if r.status_code == 401:
            _token["value"] = None
            token = await _bearer(client)
            r = await client.get(
                f"{BASE_URL}{path}",
                params=clean,
                headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
            )
        r.raise_for_status()
        return _redact(r.json())


@mcp.tool()
async def list_companies(displayid: str | None = None) -> Any:
    """List Paychex companies this API key can access. displayid is the last 8 characters of the client number."""
    return await _get("/companies", {"displayid": displayid})


@mcp.tool()
async def get_company(company_id: str) -> Any:
    """Get one company by Paychex companyId."""
    return await _get(f"/companies/{_id(company_id)}")


@mcp.tool(description="List a company-level collection (offset/limit apply to checks only). resource is one of: " + ", ".join(sorted(COMPANY_RESOURCES)))
async def company_resource(
    company_id: str, resource: str, offset: int | None = None, limit: int | None = None
) -> Any:
    if resource not in COMPANY_RESOURCES:
        raise ValueError(f"resource must be one of {sorted(COMPANY_RESOURCES)}")
    paging = {"offset": offset, "limit": limit} if resource == "checks" else {}
    return await _get(f"/companies/{_id(company_id)}/{resource}", paging)


@mcp.tool()
async def list_workers(
    company_id: str,
    givenname: str | None = None,
    familyname: str | None = None,
    employeeid: str | None = None,
    locationid: str | None = None,
    status: str | None = None,
) -> Any:
    """Search or list workers in a company."""
    return await _get(
        f"/companies/{_id(company_id)}/workers",
        {"givenname": givenname, "familyname": familyname, "employeeid": employeeid,
         "locationid": locationid, "status": status},
    )


@mcp.tool()
async def get_worker(worker_id: str) -> Any:
    """Get one worker by workerId."""
    return await _get(f"/workers/{_id(worker_id)}")


@mcp.tool(description="Read a worker sub-resource. resource is one of: " + ", ".join(sorted(WORKER_RESOURCES)))
async def worker_resource(worker_id: str, resource: str) -> Any:
    if resource not in WORKER_RESOURCES:
        raise ValueError(f"resource must be one of {sorted(WORKER_RESOURCES)}")
    return await _get(f"/workers/{_id(worker_id)}/{resource}")


if __name__ == "__main__":
    mcp.run()
