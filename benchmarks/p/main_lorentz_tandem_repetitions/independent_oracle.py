"""Direct adjacent-block comparison oracle for tandem-square intervals."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, OUTPUT_ERROR,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, OUTPUT_ERROR,
    )


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> list[int] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != n + 1:
        return None
    symbols = list(values[1:])
    if any(symbol < 0 or symbol > 255 for symbol in symbols):
        return None
    return symbols


def _direct(symbols: list[int]) -> list[tuple[int, int]]:
    n = len(symbols)
    repetitions: list[tuple[int, int]] = []
    for start in range(n):
        for half in range(1, (n - start) // 2 + 1):
            if all(symbols[start + i] == symbols[start + half + i] for i in range(half)):
                repetitions.append((start, half))
    return repetitions


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    symbols = _parse(values, input_is_null, input_length)
    if symbols is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    repetitions = _direct(symbols)
    words = [len(repetitions)] + [start * 32 + half for start, half in repetitions]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return OUTPUT_ERROR, b""
    return len(payload), payload
