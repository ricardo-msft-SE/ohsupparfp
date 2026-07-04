import asyncio
import logging
import os
from io import BytesIO

import aiohttp
from botbuilder.core import ActivityHandler, MessageFactory, TurnContext
from docx import Document
from pypdf import PdfReader

from agent_client import FoundryAgentClient

MAX_TEXT_CHARS = int(os.environ.get("MAX_TEXT_CHARS", "120000"))

# Module-level client so it is reused across warm invocations.
_agent_client = FoundryAgentClient()


def _extract_pdf_text(pdf_bytes: bytes) -> str:
    reader = PdfReader(BytesIO(pdf_bytes))
    parts = []
    for page in reader.pages:
        text = page.extract_text()
        if text:
            parts.append(text)
    return "\n".join(parts)


def _extract_docx_text(docx_bytes: bytes) -> str:
    doc = Document(BytesIO(docx_bytes))
    parts = []
    for element in doc.element.body:
        if element.tag.endswith("p"):
            para = next((p for p in doc.paragraphs if p._element is element), None)
            if para and para.text.strip():
                parts.append(para.text.strip())
        elif element.tag.endswith("tbl"):
            table_obj = next((t for t in doc.tables if t._element is element), None)
            if table_obj:
                for row in table_obj.rows:
                    cells = [c.text.strip() for c in row.cells]
                    parts.append("| " + " | ".join(cells) + " |")
    return "\n".join(parts)


def _extract_file_text(file_bytes: bytes, filename: str) -> str:
    """Route to the right extractor based on file extension."""
    if filename.lower().endswith(".docx"):
        return _extract_docx_text(file_bytes)
    return _extract_pdf_text(file_bytes)


def _trim_text(text: str) -> str:
    return text[:MAX_TEXT_CHARS] if len(text) > MAX_TEXT_CHARS else text


async def _download_file(session: aiohttp.ClientSession, url: str) -> bytes:
    async with session.get(url) as resp:
        resp.raise_for_status()
        return await resp.read()


class RfpApproverBot(ActivityHandler):
    """Teams bot adapter for the RFP Approver Foundry agent.

    Accepts two PDF file attachments in a single Teams message (the RFP document
    and the vendor response document), extracts their text, invokes the Foundry
    agent via FoundryAgentClient, and replies with the recommendation inline in
    the Teams chat thread.

    File upload protocol reference:
      https://learn.microsoft.com/en-us/microsoftteams/platform/bots/how-to/bots-filesv2
    """

    async def on_message_activity(self, turn_context: TurnContext) -> None:
        attachments = turn_context.activity.attachments or []

        file_attachments = [
            a
            for a in attachments
            if a.content_type == "application/vnd.microsoft.teams.file.download.info"
        ]

        if len(file_attachments) == 0:
            await turn_context.send_activity(
                MessageFactory.text(
                    "**RFP Approver** is ready.\n\n"
                    "Attach **both** documents in a **single message**:\n"
                    "1. The **RFP document** (PDF or DOCX)\n"
                    "2. The vendor **response document** (PDF or DOCX)\n\n"
                    "The first attachment is treated as the RFP; the second as the vendor response."
                )
            )
            return

        if len(file_attachments) < 2:
            await turn_context.send_activity(
                MessageFactory.text(
                    f"I received **{len(file_attachments)} file**. "
                    "Please attach **both** the RFP document and the vendor response document "
                    "together in the same message."
                )
            )
            return

        await turn_context.send_activity(
            MessageFactory.text(
                "Received both documents. Analyzing \u2014 this may take up to a minute."
            )
        )

        try:
            rfp_att = file_attachments[0]
            resp_att = file_attachments[1]

            async with aiohttp.ClientSession() as session:
                rfp_bytes = await _download_file(
                    session, rfp_att.content["downloadUrl"]
                )
                response_bytes = await _download_file(
                    session, resp_att.content["downloadUrl"]
                )

            rfp_text = _trim_text(_extract_file_text(rfp_bytes, rfp_att.name or ""))
            response_text = _trim_text(_extract_file_text(response_bytes, resp_att.name or ""))

            if not rfp_text.strip():
                await turn_context.send_activity(
                    MessageFactory.text(
                        "The **RFP document** did not contain readable text. "
                        "Please ensure it is a text-based (not scanned) PDF or DOCX."
                    )
                )
                return

            if not response_text.strip():
                await turn_context.send_activity(
                    MessageFactory.text(
                        "The **response document** did not contain readable text. "
                        "Please ensure it is a text-based (not scanned) PDF or DOCX."
                    )
                )
                return

            # generate_recommendation is synchronous (uses azure-ai-projects SDK);
            # run it in a thread pool to avoid blocking the event loop.
            recommendation = await asyncio.get_event_loop().run_in_executor(
                None,
                _agent_client.generate_recommendation,
                rfp_text,
                response_text,
            )

            await turn_context.send_activity(MessageFactory.text(recommendation))

        except Exception as exc:
            logging.error("Error in RfpApproverBot.on_message_activity: %s", exc, exc_info=True)
            await turn_context.send_activity(
                MessageFactory.text(
                    f"An error occurred while processing your documents:\n\n`{exc}`"
                )
            )
