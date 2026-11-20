"""Exhaustive deletion-subset reference for the bounded RLE objective."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_ALPHABET_SYMBOL,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX
           for value in values):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    count, budget = values[0], values[1]
    if not 0 <= count <= MAX_N or not 0 <= budget <= count:
        return None
    if len(values) != count + 2:
        return None
    symbols = list(values[2:])
    if any(symbol < 0 or symbol > MAX_ALPHABET_SYMBOL for symbol in symbols):
        return None
    return symbols, budget


def _encoded_length(retained: list[int]) -> int:
    total = 0
    cursor = 0
    while cursor < len(retained):
        end = cursor + 1
        while end < len(retained) and retained[end] == retained[cursor]:
            end += 1
        run_length = end - cursor
        total += 1 if run_length == 1 else 1 + len(str(run_length))
        cursor = end
    return total


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1
    symbols, budget = parsed
    n = len(symbols)
    best = n + 1
    for deletion_mask in range(1 << n):
        deleted = deletion_mask.bit_count()
        if deleted > budget:
            continue
        retained = [symbols[i] for i in range(n) if not (deletion_mask >> i) & 1]
        best = min(best, _encoded_length(retained))
    return best
