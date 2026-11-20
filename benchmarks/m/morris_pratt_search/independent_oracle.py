"""Direct window-by-window oracle for Morris–Pratt benchmark fixtures."""

from __future__ import annotations

from .primary_oracle import _decode, _pack


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    text, pattern = decoded
    matches: list[int] = []
    for start in range(len(text) - len(pattern) + 1):
        if all(text[start + offset] == symbol
               for offset, symbol in enumerate(pattern)):
            matches.append(start)
    return _pack(matches)
