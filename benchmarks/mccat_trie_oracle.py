"""Independent oracle for the bounded McCAT trie word-printing profile."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

MAX_WORDS = 64
MAX_WORD_LENGTH = 32
MAX_INPUT_VALUES = 1 + MAX_WORDS * (1 + MAX_WORD_LENGTH)
MIN_TOKEN_BYTE = 33
MAX_TOKEN_BYTE = 126


@dataclass
class _Node:
    value: int
    terminal: bool = False
    postfix: _Node | None = None
    other_char: _Node | None = None


def _suffix(values: Sequence[int], start: int, length: int) -> _Node:
    root = _Node(values[start])
    current = root
    for offset in range(1, length):
        child = _Node(values[start + offset])
        current.postfix = child
        current = child
    current.terminal = True
    return root


def _insert(current: _Node, values: Sequence[int], start: int, length: int, offset: int) -> None:
    if current.value == values[start + offset]:
        if offset + 1 == length:
            current.terminal = True
        elif current.postfix is None:
            current.postfix = _suffix(values, start + offset + 1, length - offset - 1)
        else:
            _insert(current.postfix, values, start, length, offset + 1)
    elif current.other_char is None:
        current.other_char = _suffix(values, start + offset, length - offset)
    else:
        _insert(current.other_char, values, start, length, offset)


def mccat_trie(values: Sequence[int] | None) -> tuple[int, bytes]:
    """Return ``(byte_length, output)`` or ``(-1, b"")`` for invalid input."""
    if values is None or not 1 <= len(values) <= MAX_INPUT_VALUES:
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_WORDS:
        return -1, b""

    records: list[tuple[int, int]] = []
    position = 1
    for _ in range(count):
        if position >= len(values):
            return -1, b""
        word_length = values[position]
        position += 1
        if not 1 <= word_length <= MAX_WORD_LENGTH or word_length > len(values) - position:
            return -1, b""
        start = position
        for value in values[start : start + word_length]:
            if not MIN_TOKEN_BYTE <= value <= MAX_TOKEN_BYTE:
                return -1, b""
        records.append((start, word_length))
        position += word_length
    if position != len(values):
        return -1, b""

    root: _Node | None = None
    for start, word_length in records:
        if root is None:
            root = _suffix(values, start, word_length)
        else:
            _insert(root, values, start, word_length, 0)

    words: list[bytes] = []

    def visit(node: _Node | None, prefix: bytearray) -> None:
        if node is None:
            return
        prefix.append(node.value)
        if node.terminal:
            words.append(bytes(prefix))
        visit(node.postfix, prefix)
        prefix.pop()
        visit(node.other_char, prefix)

    if root is not None:
        visit(root, bytearray())
    output = b"".join(word + b"\n" for word in words)
    return len(output), output
