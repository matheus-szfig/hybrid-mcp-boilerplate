from mcp.server.fastmcp import FastMCP

from src.services.words import add_word, clear_words, delete_word, list_words, update_word


def register_words_tools(server: FastMCP) -> None:

    @server.tool()
    def words_list() -> list[str]:
        """List all words sorted alphabetically."""
        return list_words()

    @server.tool()
    def words_add(word: str) -> list[str]:
        """Add a new unique word. Returns the updated list."""
        return add_word(word)

    @server.tool()
    def words_update(old: str, new: str) -> list[str]:
        """Rename an existing word. Returns the updated list."""
        return update_word(old, new)

    @server.tool()
    def words_delete(word: str) -> list[str]:
        """Delete a word. Returns the updated list."""
        return delete_word(word)

    @server.tool()
    def words_clear() -> None:
        """Delete all words."""
        clear_words()
