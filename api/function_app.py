import json
import os
import re
import uuid
from datetime import datetime
from io import BytesIO

import azure.functions as func
from azure.core.exceptions import ResourceNotFoundError
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from pypdf import PdfReader

from agent_client import FoundryAgentClient

MAX_TEXT_CHARS = int(os.environ.get("MAX_TEXT_CHARS", "120000"))
AZURE_STORAGE_ACCOUNT_NAME = os.environ.get("AZURE_STORAGE_ACCOUNT_NAME", "")
AZURE_STORAGE_CONTAINER_NAME = os.environ.get("AZURE_STORAGE_CONTAINER_NAME", "html-artifacts")

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

agent_client = FoundryAgentClient()

blob_service_client: BlobServiceClient | None = None
if AZURE_STORAGE_ACCOUNT_NAME:
    try:
        blob_service_client = BlobServiceClient(
            account_url=f"https://{AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net",
            credential=DefaultAzureCredential(),
        )
    except Exception as exc:
        print(f"Warning: Could not initialize blob storage client: {exc}")


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps({"status": "ok"}),
        mimetype="application/json",
    )


@app.route(route="recommend", methods=["POST"])
def recommend(req: func.HttpRequest) -> func.HttpResponse:
    content_type = req.headers.get("content-type", "")
    if "multipart/form-data" not in content_type:
        return _error(400, "Expected multipart/form-data request.")

    body = req.get_body()
    try:
        files = _parse_multipart(body, content_type)
    except Exception as exc:
        return _error(400, f"Failed to parse request body: {exc}")

    rfp_entry = files.get("rfp_document")
    response_entry = files.get("response_document")

    if rfp_entry is None:
        return _error(400, "Missing field: rfp_document")
    if response_entry is None:
        return _error(400, "Missing field: response_document")

    rfp_filename, rfp_bytes = rfp_entry
    response_filename, response_bytes = response_entry

    if not rfp_filename.lower().endswith(".pdf"):
        return _error(400, "RFP document must be a PDF.")
    if not response_filename.lower().endswith(".pdf"):
        return _error(400, "Response document must be a PDF.")

    rfp_text = _extract_pdf_text(rfp_bytes)
    vendor_response_text = _extract_pdf_text(response_bytes)

    if not rfp_text.strip():
        return _error(400, "RFP document did not contain readable text.")
    if not vendor_response_text.strip():
        return _error(400, "Response document did not contain readable text.")

    rfp_text = _trim_text(rfp_text)
    vendor_response_text = _trim_text(vendor_response_text)

    try:
        recommendation = agent_client.generate_recommendation(rfp_text, vendor_response_text)
    except Exception as exc:
        return _error(500, f"Agent invocation failed: {exc}")

    artifact_url: str | None = None
    html_content = _extract_html_from_recommendation(recommendation)
    if html_content and blob_service_client:
        try:
            artifact_name = _upload_html_to_blob(html_content)
            artifact_url = f"/api/artifacts/{artifact_name}"
        except Exception as exc:
            print(f"Warning: Could not upload HTML to blob storage: {exc}")

    result: dict[str, str] = {"recommendation": recommendation}
    if artifact_url:
        result["htmlArtifactUrl"] = artifact_url

    return func.HttpResponse(
        json.dumps(result),
        mimetype="application/json",
    )


@app.route(route="artifacts/{blob_name}", methods=["GET"])
def get_artifact(req: func.HttpRequest) -> func.HttpResponse:
    blob_name = req.route_params.get("blob_name", "")

    if not blob_service_client:
        return _error(503, "Artifact storage is not configured.")

    blob_client = blob_service_client.get_blob_client(
        container=AZURE_STORAGE_CONTAINER_NAME,
        blob=blob_name,
    )

    try:
        content = blob_client.download_blob().readall()
    except ResourceNotFoundError:
        return _error(404, "Artifact not found.")
    except Exception:
        return _error(500, "Failed to read artifact.")

    return func.HttpResponse(
        body=content,
        mimetype="text/html; charset=utf-8",
        headers={"Content-Disposition": f'inline; filename="{blob_name}"'},
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _error(status: int, detail: str) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps({"detail": detail}),
        status_code=status,
        mimetype="application/json",
    )


def _parse_multipart(body: bytes, content_type_header: str) -> dict[str, tuple[str, bytes]]:
    """Parse multipart/form-data body. Returns dict of field_name -> (filename, data)."""
    boundary_match = re.search(r'boundary=([^\s;]+)', content_type_header, re.IGNORECASE)
    if not boundary_match:
        raise ValueError("No boundary found in Content-Type header.")

    boundary = boundary_match.group(1).strip('"').encode()
    delimiter = b"--" + boundary
    result: dict[str, tuple[str, bytes]] = {}

    for part in body.split(delimiter):
        # Skip the preamble, epilogue, and closing delimiter
        if not part or part.strip() in (b"", b"--", b"--\r\n"):
            continue
        # Strip leading CRLF
        if part.startswith(b"\r\n"):
            part = part[2:]
        # Strip trailing CRLF before the next delimiter
        if part.endswith(b"\r\n"):
            part = part[:-2]

        if b"\r\n\r\n" not in part:
            continue

        headers_raw, _, data = part.partition(b"\r\n\r\n")
        headers_str = headers_raw.decode("utf-8", errors="replace")

        cd_match = re.search(r'Content-Disposition:[^\r\n]+', headers_str, re.IGNORECASE)
        if not cd_match:
            continue

        cd = cd_match.group(0)
        name_match = re.search(r'name="([^"]*)"', cd, re.IGNORECASE)
        filename_match = re.search(r'filename="([^"]*)"', cd, re.IGNORECASE)

        name = name_match.group(1) if name_match else None
        filename = filename_match.group(1) if filename_match else ""

        if name is not None:
            result[name] = (filename, data)

    return result


def _extract_pdf_text(file_bytes: bytes) -> str:
    reader = PdfReader(BytesIO(file_bytes))
    pages: list[str] = []
    for page in reader.pages:
        pages.append(page.extract_text() or "")
    return "\n".join(pages)


def _trim_text(text: str) -> str:
    if len(text) <= MAX_TEXT_CHARS:
        return text
    return text[:MAX_TEXT_CHARS] + "\n\n[Truncated to fit processing limits.]"


def _extract_html_from_recommendation(recommendation: str) -> str | None:
    if not recommendation:
        return None

    if ":::writing" in recommendation:
        start_idx = recommendation.find(":::writing") + len(":::writing")
        end_idx = recommendation.rfind(":::")
        if end_idx > start_idx:
            html_candidate = recommendation[start_idx:end_idx].strip()
            if html_candidate.startswith("<!DOCTYPE html>") or html_candidate.startswith("<html"):
                return html_candidate

    start_marker = "<!DOCTYPE html>"
    if start_marker not in recommendation:
        start_marker = "<html"

    if start_marker in recommendation:
        start_idx = recommendation.find(start_marker)
        end_idx = recommendation.rfind("</html>")
        if end_idx > start_idx:
            return recommendation[start_idx:end_idx + 7]

    return None


def _upload_html_to_blob(html_content: str) -> str:
    if not blob_service_client or not AZURE_STORAGE_ACCOUNT_NAME:
        raise ValueError("Blob storage is not configured.")

    blob_name = f"evaluation-{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:8]}.html"
    container_client = blob_service_client.get_container_client(AZURE_STORAGE_CONTAINER_NAME)
    blob_client = container_client.get_blob_client(blob_name)
    blob_client.upload_blob(html_content, overwrite=True)
    return blob_name
