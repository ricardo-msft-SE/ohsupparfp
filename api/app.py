"""
Plain aiohttp HTTP server — replaces the Azure Functions host.

Exposes:
  GET  /api/health    → {"status": "ok"}
  POST /api/messages  → Bot Framework Teams messaging endpoint
"""
import json
import logging
import os

from aiohttp import web
from botbuilder.schema import Activity

from bot_adapter import adapter
from teams_bot import RfpApproverBot

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def health(request: web.Request) -> web.Response:
    return web.Response(
        text=json.dumps({"status": "ok"}),
        content_type="application/json",
    )


async def messages(request: web.Request) -> web.Response:
    """Bot Framework messaging endpoint for Azure Bot Service / Teams."""
    try:
        body = await request.json()
    except Exception:
        return web.Response(
            text=json.dumps({"detail": "Invalid JSON body."}),
            status=400,
            content_type="application/json",
        )

    activity = Activity().deserialize(body)
    auth_header = request.headers.get("Authorization", "")

    bot = RfpApproverBot()
    try:
        invoke_response = await adapter.process_activity(activity, auth_header, bot.on_turn)
    except PermissionError as e:
        logger.warning("Auth error processing activity: %s", e)
        return web.Response(status=401, text="Unauthorized")
    except (TypeError, ValueError) as e:
        logger.warning("Invalid activity: %s", e)
        return web.Response(status=400, text="Bad Request")
    except Exception as e:
        logger.error("Unhandled error in messages: %s", e, exc_info=True)
        return web.Response(status=500, text="Internal Server Error")

    if invoke_response:
        return web.Response(
            text=json.dumps(invoke_response.body),
            status=invoke_response.status,
            content_type="application/json",
        )
    return web.Response(status=200)


def create_app() -> web.Application:
    a = web.Application()
    a.router.add_get("/api/health", health)
    a.router.add_post("/api/messages", messages)
    return a


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "80"))
    web.run_app(create_app(), host="0.0.0.0", port=port)
