"""Right-to-left finite-fraction oracle for continued-fraction convergents."""

from __future__ import annotations

import struct
from typing import Sequence

ALGORITHM = "continued_fraction_convergents"
MAX_COEFFICIENTS = 16
MAX_FIRST_COEFFICIENT = 1000
MAX_TAIL_COEFFICIENT = 8
MAX_VALID_INPUT_LENGTH = 17
MAX_PARSEABLE_INPUT_LENGTH = 18
MAX_OUTPUT_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
WORKSPACE_BYTES = 64


def _parse(values: Sequence[int] | None,
           input_is_null: bool,
           input_length: int | None) -> list[int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if not 1 <= count <= MAX_COEFFICIENTS or len(values) != count + 1:
        return None
    coefficients = list(values[1:])
    if not -MAX_FIRST_COEFFICIENT <= coefficients[0] <= MAX_FIRST_COEFFICIENT:
        return None
    if any(not 1 <= value <= MAX_TAIL_COEFFICIENT for value in coefficients[1:]):
        return None
    return coefficients


def _all_prefixes_from_tail(coefficients: Sequence[int]) -> list[int]:
    words: list[int] = []
    for end in range(len(coefficients)):
        numerator = coefficients[end]
        denominator = 1
        for index in range(end - 1, -1, -1):
            numerator, denominator = (
                coefficients[index] * numerator + denominator,
                numerator,
            )
        words.extend((numerator, denominator))
    return words


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    coefficients = _parse(values, input_is_null, input_length)
    if coefficients is None:
        return INVALID_RESULT, b""
    required = 16 * len(coefficients)
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = _all_prefixes_from_tail(coefficients)
    return required, struct.pack("<" + "q" * len(words), *words)
