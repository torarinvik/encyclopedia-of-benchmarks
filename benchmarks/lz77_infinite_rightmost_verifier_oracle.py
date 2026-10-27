"""Independent LCP-table verifier for rightmost infinite-window LZ77."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 1536


def _decode(data: Sequence[int] | None):
    if (not isinstance(data, (list, tuple)) or not 1 <= len(data) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in data)):
        return None
    n = data[0]
    if type(n) is not int or not 0 <= n <= MAX_TEXT_LENGTH or len(data) != n + 1:
        return None
    text = tuple(data[1:])
    if any(not 32 <= ch <= 126 for ch in text):
        return None
    return text


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    text = _decode(values)
    if text is None:
        return -1, b""
    n = len(text)
    # lcp[i][j] is the common-prefix length of the two suffixes beginning at
    # i and j. It bounds matches by the target suffix and allows overlap.
    lcp = [[0] * (n + 1) for _ in range(n + 1)]
    for i in range(n - 1, -1, -1):
        for j in range(n - 1, -1, -1):
            if text[i] == text[j]:
                lcp[i][j] = 1 + lcp[i + 1][j + 1]
    tokens: list[tuple[int, int, int]] = []
    q = 0
    while q < n:
        best_len = 0
        best_pos = -1
        for p in range(q):
            candidate = lcp[p][q]
            if candidate > best_len or candidate == best_len and candidate > 0 and p > best_pos:
                best_len, best_pos = candidate, p
        source_pos = best_pos if best_len else 0
        next_pos = q + best_len
        next_char = text[next_pos] if next_pos < n else 0
        tokens.append((source_pos, best_len, next_char))
        q = next_pos + 1 if next_char else next_pos
    payload = b"".join(struct.pack("<qqq", *token) for token in tokens)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
