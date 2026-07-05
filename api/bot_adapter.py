import logging
import os

from botbuilder.core import BotFrameworkAdapter, BotFrameworkAdapterSettings

MICROSOFT_APP_ID = os.environ.get("MICROSOFT_APP_ID", "")
MICROSOFT_APP_PASSWORD = os.environ.get("MICROSOFT_APP_PASSWORD", "")
# Required for single-tenant bots so replies authenticate against the correct AAD tenant
# rather than the default multi-tenant Bot Framework endpoint.
MICROSOFT_APP_TENANT_ID = os.environ.get("MICROSOFT_APP_TENANT_ID", "")

settings = BotFrameworkAdapterSettings(
    app_id=MICROSOFT_APP_ID,
    app_password=MICROSOFT_APP_PASSWORD,
    channel_auth_tenant=MICROSOFT_APP_TENANT_ID or None,
)

adapter = BotFrameworkAdapter(settings)


async def _on_error(context, error: Exception) -> None:
    logging.error("Unhandled bot error: %s", error, exc_info=True)
    try:
        await context.send_activity("The bot encountered an unexpected error. Please try again.")
    except Exception:
        pass


adapter.on_turn_error = _on_error
