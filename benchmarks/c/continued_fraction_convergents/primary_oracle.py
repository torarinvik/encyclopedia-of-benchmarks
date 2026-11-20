"""Linear recurrence reference for bounded continued-fraction convergents."""

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


def _coefficients(values: Sequence[int] | None,
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
    if not -MAX_FIRST_COEFFICIENT <= values[1] <= MAX_FIRST_COEFFICIENT:
        return None
    if any(not 1 <= value <= MAX_TAIL_COEFFICIENT for value in values[2:]):
        return None
    return list(values[1:])


def convergent_words(coefficients: Sequence[int]) -> list[int]:
    p_two_back, p_one_back = 0, 1
    q_two_back, q_one_back = 1, 0
    words: list[int] = []
    for coefficient in coefficients:
        numerator = coefficient * p_one_back + p_two_back
        denominator = coefficient * q_one_back + q_two_back
        words.extend((numerator, denominator))
        p_two_back, p_one_back = p_one_back, numerator
        q_two_back, q_one_back = q_one_back, denominator
    return words


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    coefficients = _coefficients(values, input_is_null, input_length)
    if coefficients is None:
        return INVALID_RESULT, b""
    required = 16 * len(coefficients)
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = convergent_words(coefficients)
    return required, struct.pack("<" + "q" * len(words), *words)
