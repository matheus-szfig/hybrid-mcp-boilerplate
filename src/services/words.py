from pathlib import Path

WORDS_FILE = Path("words.txt")


def _read() -> list[str]:
    if not WORDS_FILE.exists():
        return []
    return WORDS_FILE.read_text(encoding="utf-8").splitlines()


def _write(words: list[str]) -> None:
    WORDS_FILE.write_text("\n".join(sorted(set(words))), encoding="utf-8")


def list_words() -> list[str]:
    return _read()


def add_word(word: str) -> list[str]:
    words = _read()
    if word in words:
        return words
    _write([*words, word])
    return _read()


def update_word(old: str, new: str) -> list[str]:
    words = _read()
    if old not in words:
        raise ValueError(f"Word '{old}' not found")
    if new in words:
        raise ValueError(f"Word '{new}' already exists")
    _write([new if w == old else w for w in words])
    return _read()


def delete_word(word: str) -> list[str]:
    words = _read()
    if word not in words:
        raise ValueError(f"Word '{word}' not found")
    _write([w for w in words if w != word])
    return _read()


def clear_words() -> None:
    _write([])
