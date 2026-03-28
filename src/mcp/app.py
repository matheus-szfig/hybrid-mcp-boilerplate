from mcp.server.fastmcp import FastMCP

from src.mcp.tools.words import register_words_tools
from src.settings import settings

mcp = FastMCP(name=settings.app_name)

register_words_tools(mcp)
