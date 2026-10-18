"""Oracle for the bounded, source-faithful Java LZ78 compressor."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_INPUT_LENGTH = 0
MAX_INPUT_LENGTH = 64
MIN_CHARACTER = 32
MAX_CHARACTER = 126
END_OF_STREAM = 0
MAX_VALID_INPUT_LENGTH = 1 + MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16 * MAX_INPUT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


class _TrieNode:
    __slots__ = ("children", "index")

    def __init__(self, index: int = -1) -> None:
        self.children: dict[int, _TrieNode] = {}
        self.index = index


def _decode_input(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None

    length = values[0]
    if not MIN_INPUT_LENGTH <= length <= MAX_INPUT_LENGTH:
        return None
    if len(values) != 1 + length:
        return None
    characters = values[1:]
    if any(not MIN_CHARACTER <= value <= MAX_CHARACTER for value in characters):
        return None
    return characters


def _compress(characters: Sequence[int]) -> list[tuple[int, int]]:
    root = _TrieNode(0)
    current = root
    last_matched_index = 0
    next_dictionary_index = 1
    tokens: list[tuple[int, int]] = []

    for character in characters:
        child = current.children.get(character)
        if child is not None:
            current = child
            last_matched_index = current.index
        else:
            tokens.append((last_matched_index, character))
            current.children[character] = _TrieNode(next_dictionary_index)
            next_dictionary_index += 1
            current = root
            last_matched_index = 0

    if current is not root:
        tokens.append((last_matched_index, END_OF_STREAM))
    return tokens


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return little-endian (dictionary-index, character) pairs or ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    characters = _decode_input(values)
    if characters is None:
        return INVALID_RESULT, b""
    tokens = _compress(characters)
    output = b"".join(
        struct.pack("<qq", dictionary_index, character)
        for dictionary_index, character in tokens
    )
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
