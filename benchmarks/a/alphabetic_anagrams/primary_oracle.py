"""Multiplicity-aware lexicographic rank using multinomial block sizes."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 8
MAX_SYMBOL = 25
MAX_ALPHABET = MAX_SYMBOL + 1
MAX_VALID_INPUT_LENGTH = MAX_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 40320
MAX_WORKSPACE_BYTES = MAX_ALPHABET * 8
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    length = values[0]
    if not 0 <= length <= MAX_LENGTH or len(values) != length + 1:
        return None
    symbols = tuple(values[1:])
    if any(symbol < 0 or symbol > MAX_SYMBOL for symbol in symbols):
        return None
    return symbols


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    symbols = _parse(values, input_is_null, input_length)
    if symbols is None:
        return INVALID_RESULT
    frequencies = [0] * MAX_ALPHABET
    for symbol in symbols:
        frequencies[symbol] += 1

    total = 1
    for factor in range(2, len(symbols) + 1):
        total *= factor
    denominator = 1
    for frequency in frequencies:
        factorial = 1
        for factor in range(2, frequency + 1):
            factorial *= factor
        denominator *= factorial
    ways = total // denominator

    rank = 1
    remaining = len(symbols)
    for actual in symbols:
        for smaller in range(actual):
            if frequencies[smaller] != 0:
                rank += ways * frequencies[smaller] // remaining
        ways = ways * frequencies[actual] // remaining if remaining else ways
        frequencies[actual] -= 1
        remaining -= 1
    return rank
