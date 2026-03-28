from src.api import app
from src.mcp import mcp

app.mount("/mcp", mcp.sse_app())