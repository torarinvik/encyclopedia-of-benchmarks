"""Direct continuant-pair reference for Lentz convergent traces."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "lentz_continued_fraction_convergents"
MODULUS = 998244353
MIN_TERMS = 1
MAX_TERMS = 8
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_TERMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_TERMS + 2)
WORKSPACE_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    count = values[0]
    if not MIN_TERMS <= count <= MAX_TERMS or actual_length != 2 + 2 * count:
        return None
    for value in values[1:]:
        if value < 0 or value >= MODULUS:
            return None
    initial = values[1]
    if initial == 0:
        return None
    pairs = []
    for index in range(count):
        pairs.append((values[2 + 2 * index], values[3 + 2 * index]))
    return count, initial, pairs


def continuant_trace(initial: int, terms: Sequence[tuple[int, int]]) -> list[int] | None:
    """Build A_n and B_n directly, then divide each exact field pair."""
    a_before, a_current = 1, initial
    b_before, b_current = 0, 1
    trace = [initial]
    for numerator, denominator in terms:
        a_next = (denominator * a_current + numerator * a_before) % MODULUS
        b_next = (denominator * b_current + numerator * b_before) % MODULUS
        # The package pins the strict nonsingular Lentz domain: both C_n and
        # the pre-inversion D_n denominator must be nonzero at every step.
        if a_current == 0 or a_next == 0 or b_next == 0:
            return None
        trace.append(a_next * pow(b_next, MODULUS - 2, MODULUS) % MODULUS)
        a_before, a_current = a_current, a_next
        b_before, b_current = b_current, b_next
    return trace


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    count, initial, terms = parsed
    trace = continuant_trace(initial, terms)
    if trace is None:
        return INVALID_RESULT, b""
    required = 8 * (count + 2)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < 0
            or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    return required, struct.pack("<" + "q" * (count + 2), count + 1, *trace)
