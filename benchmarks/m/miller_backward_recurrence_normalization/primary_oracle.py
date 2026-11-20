"""Miller terminal-trial backward recurrence and finite functional normalization."""

from __future__ import annotations

import struct
from typing import Sequence

ALGORITHM = "miller_backward_recurrence_normalization"
MODULUS = 998244353
MIN_LEVELS = 1
MAX_LEVELS = 8
MIN_VALID_INPUT_LENGTH = 6
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 192
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int, int]], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not MIN_VALID_INPUT_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    levels = values[0]
    if not MIN_LEVELS <= levels <= MAX_LEVELS or len(values) != 4 * levels + 2:
        return None
    if any(not 0 <= value < MODULUS for value in values[1:]):
        return None
    triples = [tuple(values[1 + 3 * index:4 + 3 * index]) for index in range(levels)]
    lambdas = list(values[3 * levels + 1:4 * levels + 2])
    if any(c_value == 0 for _, _, c_value in triples):
        return None
    return levels, triples, lambdas


def miller_trial_vector(triples: Sequence[tuple[int, int, int]],
                        lambdas: Sequence[int]) -> list[int] | None:
    levels = len(triples)
    trial = [0] * (levels + 2)
    trial[levels] = 1
    trial[levels + 1] = 0
    for level in range(levels, 0, -1):
        a_value, b_value, c_value = triples[level - 1]
        numerator = (b_value * trial[level] - a_value * trial[level + 1]) % MODULUS
        trial[level - 1] = numerator * pow(c_value, MODULUS - 2, MODULUS) % MODULUS
    normalizer = sum(lambdas[index] * trial[index] for index in range(levels + 1)) % MODULUS
    if normalizer == 0:
        return None
    scale = pow(normalizer, MODULUS - 2, MODULUS)
    return [value * scale % MODULUS for value in trial[:levels + 1]]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    levels, triples, lambdas = parsed
    normalized = miller_trial_vector(triples, lambdas)
    if normalized is None:
        return INVALID_RESULT, b""
    required = 8 * (levels + 2)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < 0
            or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = [levels, *normalized]
    return required, struct.pack("<" + "q" * len(words), *words)
