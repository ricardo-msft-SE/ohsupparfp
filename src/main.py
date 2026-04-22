import os
from io import BytesIO
from datetime import datetime
import uuid

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import FileResponse, Response
from fastapi.staticfiles import StaticFiles
from pypdf import PdfReader
from azure.core.exceptions import ResourceNotFoundError
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential

from src.agent_client import FoundryAgentClient


MAX_TEXT_CHARS = int(os.environ.get("MAX_TEXT_CHARS", "120000"))
AZURE_STORAGE_ACCOUNT_NAME = os.environ.get("AZURE_STORAGE_ACCOUNT_NAME", "")
AZURE_STORAGE_CONTAINER_NAME = os.environ.get("AZURE_STORAGE_CONTAINER_NAME", "html-artifacts")

app = FastAPI(title="RFP Approver Landing Page")
app.mount("/static", StaticFiles(directory="src/static"), name="static")

agent_client = FoundryAgentClient()

# Initialize blob storage client if storage account is configured
blob_service_client = None
if AZURE_STORAGE_ACCOUNT_NAME:
    try:
        blob_service_client = BlobServiceClient(
            account_url=f"https://{AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net",
            credential=DefaultAzureCredential()
        )
    except Exception as e:
        print(f"Warning: Could not initialize blob storage client: {e}")


@app.get("/")
def index() -> FileResponse:
    return FileResponse("src/static/index.html")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/artifacts/{blob_name}")
def get_artifact(blob_name: str) -> Response:
    if not blob_service_client:
        raise HTTPException(status_code=503, detail="Artifact storage is not configured.")

    blob_client = blob_service_client.get_blob_client(
        container=AZURE_STORAGE_CONTAINER_NAME,
        blob=blob_name,
    )

    try:
        content = blob_client.download_blob().readall()
    except ResourceNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Artifact not found.") from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Failed to read artifact.") from exc

    return Response(
        content=content,
        media_type="text/html; charset=utf-8",
        headers={"Content-Disposition": f'inline; filename="{blob_name}"'},
    )


@app.post("/api/recommend")
async def recommend(
    rfp_document: UploadFile = File(...),
    response_document: UploadFile = File(...),
) -> dict[str, str]:
    if not rfp_document.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="RFP document must be a PDF.")
    if not response_document.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Response document must be a PDF.")

    rfp_bytes = await rfp_document.read()
    response_bytes = await response_document.read()

    rfp_text = _extract_pdf_text(rfp_bytes)
    vendor_response_text = _extract_pdf_text(response_bytes)

    if not rfp_text.strip():
        raise HTTPException(status_code=400, detail="RFP document did not contain readable text.")
    if not vendor_response_text.strip():
        raise HTTPException(status_code=400, detail="Response document did not contain readable text.")

    rfp_text = _trim_text(rfp_text)
    vendor_response_text = _trim_text(vendor_response_text)

    try:
        recommendation = agent_client.generate_recommendation(rfp_text, vendor_response_text)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Agent invocation failed: {exc}") from exc

    # Extract HTML from recommendation and upload to blob storage
    artifact_url = None
    html_content = _extract_html_from_recommendation(recommendation)
    if html_content and blob_service_client:
        try:
            artifact_name = _upload_html_to_blob(html_content)
            artifact_url = f"/api/artifacts/{artifact_name}"
        except Exception as e:
            print(f"Warning: Could not upload HTML to blob storage: {e}")
            # Continue anyway - the recommendation is still valid even if blob upload fails

    result = {"recommendation": recommendation}
    if artifact_url:
        result["htmlArtifactUrl"] = artifact_url

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
    """Extract HTML content from recommendation response.
    
    The Foundry agent includes HTML as a structured artifact with various markers.
    This function extracts it if present.
    """
    if not recommendation:
        return None
    
    # Check for :::writing marker format (Foundry's markdown wrapper)
    if ":::writing" in recommendation:
        start_idx = recommendation.find(":::writing") + len(":::writing")
        end_idx = recommendation.rfind(":::")
        if end_idx > start_idx:
            html_candidate = recommendation[start_idx:end_idx].strip()
            if html_candidate.startswith("<!DOCTYPE html>") or html_candidate.startswith("<html"):
                return html_candidate
    
    # Fallback: Look for raw HTML markers
    start_marker = "<!DOCTYPE html>"
    if start_marker not in recommendation:
        start_marker = "<html"
    
    if start_marker in recommendation:
        start_idx = recommendation.find(start_marker)
        end_idx = recommendation.rfind("</html>")
        if end_idx > start_idx:
            return recommendation[start_idx:end_idx + 7]  # +7 for </html>
    
    return None


def _upload_html_to_blob(html_content: str) -> str:
    """Upload HTML content to blob storage and return the blob name.
    
    Args:
        html_content: The HTML content to upload
        
    Returns:
        Blob name for later retrieval
        
    Raises:
        Exception: If blob upload fails
    """
    if not blob_service_client or not AZURE_STORAGE_ACCOUNT_NAME:
        raise ValueError("Blob storage is not configured")
    
    # Create a unique blob name with timestamp
    blob_name = f"evaluation-{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:8]}.html"
    
    # Get container client and upload blob
    container_client = blob_service_client.get_container_client(AZURE_STORAGE_CONTAINER_NAME)
    blob_client = container_client.get_blob_client(blob_name)
    blob_client.upload_blob(html_content, overwrite=True)
    
    return blob_name
