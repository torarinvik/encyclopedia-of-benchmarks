"""Direct alignment-by-alignment oracle for ordered-alphabet string search."""

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
        matched = 0
        while matched < m and text[start + matched] == pattern[matched]:
            matched += 1
        if matched == m:
            matches.append(start)
    return _pack(matches)
