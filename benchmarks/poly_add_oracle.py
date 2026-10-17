"""Oracle for the bounded linked-list polynomial merge benchmark."""

from __future__ import annotations

import struct

MIN_POLYNOMIAL_TERMS = 1
MAX_POLYNOMIAL_TERMS = 16
MIN_DEGREE = 0
MAX_DEGREE = 63
MIN_COEFFICIENT = -1_000_000
MAX_COEFFICIENT = 1_000_000
MAX_INPUT_LENGTH = 67  # admit one extra value after the maximum valid input
MAX_OUTPUT_BYTES = 512
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT, b""

    count_a = values[0]
    if not MIN_POLYNOMIAL_TERMS <= count_a <= MAX_POLYNOMIAL_TERMS:
        return INVALID_RESULT, b""
    count_b_index = 1 + 2 * count_a
    if len(values) <= count_b_index:
        return INVALID_RESULT, b""
    count_b = values[count_b_index]
    if not MIN_POLYNOMIAL_TERMS <= count_b <= MAX_POLYNOMIAL_TERMS:
        return INVALID_RESULT, b""
    if len(values) != 2 + 2 * (count_a + count_b):
        return INVALID_RESULT, b""

    def read_terms(start: int, count: int) -> list[tuple[int, int]] | None:
        terms = [(values[start + 2 * i], values[start + 2 * i + 1]) for i in range(count)]
        previous_degree = MAX_DEGREE + 1
        for coefficient, degree in terms:
            if (not MIN_COEFFICIENT <= coefficient <= MAX_COEFFICIENT
                    or not MIN_DEGREE <= degree <= MAX_DEGREE
                    or degree >= previous_degree):
                return None
            previous_degree = degree
        return terms

    terms_a = read_terms(1, count_a)
    terms_b = read_terms(count_b_index + 1, count_b)
    if terms_a is None or terms_b is None:
        return INVALID_RESULT, b""

    merged: list[tuple[int, int]] = []
    i = j = 0
    while i < count_a and j < count_b:
        coefficient_a, degree_a = terms_a[i]
        coefficient_b, degree_b = terms_b[j]
        if degree_a > degree_b:
            merged.append((coefficient_a, degree_a))
            i += 1
        elif degree_a < degree_b:
            merged.append((coefficient_b, degree_b))
            j += 1
        else:
            merged.append((coefficient_a + coefficient_b, degree_a))
            i += 1
            j += 1
    merged.extend(terms_a[i:])
    merged.extend(terms_b[j:])

    output = b"".join(struct.pack("<q", value) for term in merged for value in term)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
