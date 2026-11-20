"""Alignment-by-alignment reference independent of Skip Search buckets."""

from __future__ import annotations

from .primary_oracle import _decode, _pack


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    n, m = len(text), len(pattern)
    matches: list[int] = []
    for start in range(n - m + 1):
        offset = 0
        while offset < m and text[start + offset] == pattern[offset]:
            offset += 1
        if offset == m:
            matches.append(start)
    return _pack(matches)
