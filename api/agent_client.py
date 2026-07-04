import os
import json
from urllib import error, request
from typing import Any

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from azure.search.documents import SearchClient


class FoundryAgentClient:
    def __init__(self) -> None:
        self.project_endpoint = os.environ["AZURE_AI_PROJECT_ENDPOINT"]
        self.agent_name = os.environ.get("AZURE_AI_AGENT_NAME", "oh-rfpApprover1")
        self.managed_identity_client_id = os.environ.get("AZURE_CLIENT_ID")
        self.responses_api_endpoint = os.environ.get("AZURE_AI_RESPONSES_API_ENDPOINT")
        self.activity_protocol_endpoint = os.environ.get("AZURE_AI_ACTIVITY_PROTOCOL_ENDPOINT")
        self.search_endpoint = os.environ.get("AZURE_AI_SEARCH_ENDPOINT")
        self.search_index_name = os.environ.get("AZURE_AI_SEARCH_INDEX_NAME")
        self.search_top_k = int(os.environ.get("AZURE_AI_SEARCH_TOP_K", "5"))

        self.search_client = None
        if self.search_endpoint and self.search_index_name:
            self.search_client = SearchClient(
                endpoint=self.search_endpoint,
                index_name=self.search_index_name,
                credential=DefaultAzureCredential(
                    managed_identity_client_id=self.managed_identity_client_id
                ),
            )

    def generate_recommendation(self, rfp_text: str, response_text: str) -> str:
        search_context = self._fetch_search_context(rfp_text)
        prompt = self._build_user_message(rfp_text, response_text, search_context)

        if self.responses_api_endpoint:
            try:
                return self._invoke_via_responses_endpoint(prompt)
            except Exception:
                # Fall back to the project SDK flow if preview endpoint auth is not accepted.
                pass

        with (
            DefaultAzureCredential(managed_identity_client_id=self.managed_identity_client_id) as credential,
            AIProjectClient(endpoint=self.project_endpoint, credential=credential) as project_client,
            project_client.get_openai_client() as openai_client,
        ):
            conversation = openai_client.conversations.create(
                items=[
                    {
                        "type": "message",
                        "role": "user",
                        "content": prompt,
                    }
                ]
            )

            try:
                response = openai_client.responses.create(
                    conversation=conversation.id,
                    extra_body={
                        "agent_reference": {
                            "name": self.agent_name,
                            "type": "agent_reference",
                        }
                    },
                )
                text = getattr(response, "output_text", "") or self._extract_text(response)
                return text.strip() or "The agent returned an empty response."
            finally:
                try:
                    openai_client.conversations.delete(conversation_id=conversation.id)
                except Exception:
                    # Conversation cleanup failure should not fail user requests.
                    pass

    def _build_user_message(self, rfp_text: str, response_text: str, search_context: str | None) -> str:
        context_block = ""
        if search_context:
            context_block = (
                "ADDITIONAL REFERENCE CONTEXT FROM AZURE AI SEARCH:\n"
                f"{search_context}\n\n"
            )

        return (
            "Evaluate the vendor response against the RFP and provide your recommendation.\n"
            "Use the additional reference context when it is relevant and cite which snippets influenced your recommendation.\n\n"
            f"{context_block}"
            "RFP DOCUMENT:\n"
            f"{rfp_text}\n\n"
            "VENDOR RESPONSE DOCUMENT:\n"
            f"{response_text}"
        )

    def _fetch_search_context(self, rfp_text: str) -> str | None:
        if not self.search_client:
            return None

        query = self._build_search_query(rfp_text)
        if not query:
            return None

        try:
            results = self.search_client.search(search_text=query, top=self.search_top_k)
            chunks: list[str] = []

            for index, result in enumerate(results, start=1):
                source = (
                    result.get("title")
                    or result.get("source")
                    or result.get("sourcefile")
                    or result.get("metadata_storage_name")
                    or f"document-{index}"
                )

                text = (
                    result.get("content")
                    or result.get("chunk")
                    or result.get("text")
                    or result.get("description")
                    or ""
                )
                if not isinstance(text, str):
                    continue

                snippet = text.strip().replace("\n", " ")
                if not snippet:
                    continue

                chunks.append(f"[{index}] {source}: {snippet[:1200]}")

            if not chunks:
                return None

            return "\n".join(chunks)
        except Exception:
            # Search is optional context. Fail open and continue with the base prompt.
            return None

    def _build_search_query(self, rfp_text: str) -> str:
        compact = " ".join(rfp_text.split())
        return compact[:1200]

    def _invoke_via_responses_endpoint(self, prompt: str) -> str:
        with DefaultAzureCredential(managed_identity_client_id=self.managed_identity_client_id) as credential:
            # Published Foundry application protocol endpoints require ai.azure.com audience.
            try:
                access_token = credential.get_token("https://ai.azure.com/.default").token
            except Exception:
                # Fall back to the cognitive services audience for backward compatibility.
                access_token = credential.get_token("https://cognitiveservices.azure.com/.default").token

        payload = {
            "input": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": prompt,
                        }
                    ],
                }
            ]
        }
        request_body = json.dumps(payload).encode("utf-8")
        http_request = request.Request(
            self.responses_api_endpoint,
            data=request_body,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:
            with request.urlopen(http_request, timeout=180) as response:
                response_payload = json.loads(response.read().decode("utf-8"))
        except error.HTTPError as http_error:
            error_body = http_error.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Responses API call failed ({http_error.code}): {error_body}") from http_error

        text = self._extract_responses_api_text(response_payload)
        return text.strip() or "The agent returned an empty response."

    def _extract_responses_api_text(self, response_payload: dict[str, Any]) -> str:
        output_text = response_payload.get("output_text")
        if isinstance(output_text, str) and output_text.strip():
            return output_text

        output_items = response_payload.get("output", [])
        text_chunks: list[str] = []
        for item in output_items:
            if not isinstance(item, dict):
                continue
            content_items = item.get("content", [])
            for content_item in content_items:
                if not isinstance(content_item, dict):
                    continue
                text = content_item.get("text")
                if isinstance(text, str) and text:
                    text_chunks.append(text)

        return "\n".join(text_chunks)

    def _extract_text(self, response: Any) -> str:
        output_items = getattr(response, "output", [])
        text_chunks: list[str] = []

        for item in output_items:
            content_items = getattr(item, "content", [])
            for content_item in content_items:
                text = getattr(content_item, "text", None)
                if text:
                    text_chunks.append(text)

        return "\n".join(text_chunks)
