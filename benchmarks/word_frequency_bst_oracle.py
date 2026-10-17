"""Counter-and-sort oracle for the bounded BST word-frequency ABI."""
from __future__ import annotations

from collections import Counter

MAX_INPUT_BYTES = 256
MAX_TOKEN_BYTES = 45
MAX_UNIQUE_WORDS = 128
MAX_OUTPUT_BYTES = 896
PINNED_SOURCE = {
    "repository": "TheAlgorithms/C",
    "commit": "e5dad3fa8def3726ec850ca66a7f51521f8ad393",
    "path": "data_structures/binary_trees/words_alphabetical.c",
}


def _is_alpha(byte: int) -> bool:
    return 65 <= byte <= 90 or 97 <= byte <= 122


def _tokenize(data: list[int]) -> list[bytes] | None:
    words: list[bytes] = []
    token = bytearray()

    def flush() -> bool:
        if not token:
            return True
        if not _is_alpha(token[-1]) and token[-1] != ord("'"):
            token.pop()  # the pinned parser strips a final hyphen
        if token:
            words.append(bytes(token))
        token.clear()
        return True

    for byte in data:
        if _is_alpha(byte):
            if len(token) >= MAX_TOKEN_BYTES:
                return None
            token.append(byte + 32 if 65 <= byte <= 90 else byte)
            continue
        if byte in (ord("'"), ord("-")) and token and _is_alpha(token[-1]):
            if len(token) >= MAX_TOKEN_BYTES:
                return None
            token.append(byte)
            continue
        flush()
    flush()
    return words


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the result and exact `word<TAB>count<LF>` output bytes."""
    if not isinstance(values, (list, tuple)) or not values:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    text_length = values[0]
    if text_length < 0 or text_length > MAX_INPUT_BYTES or len(values) != text_length + 1:
        return -1, b""
    data = values[1:]
    if any(byte < 0 or byte > 127 for byte in data):
        return -1, b""
    words = _tokenize(data)
    if words is None:
        return -1, b""
    counts = Counter(words)
    if len(counts) > MAX_UNIQUE_WORDS:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""

    encoded = b"".join(
        word + b"\t" + str(counts[word]).encode("ascii") + b"\n"
        for word in sorted(counts)
    )
    if len(encoded) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
