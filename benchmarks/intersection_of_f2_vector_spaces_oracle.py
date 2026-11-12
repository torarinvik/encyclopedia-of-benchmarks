"""Small-span enumeration oracle for GF(2) vector-space intersections."""

import struct

MAX_CASES = 4
MAX_N = 8
MAX_M = 8
MAX_VECTOR = (1 << 30) - 1
MAX_VALID_INPUT_LENGTH = 1 + MAX_CASES * (2 + MAX_N + MAX_M)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = MAX_CASES * (1 + min(MAX_N, MAX_M))
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS


def _span(vectors):
    values = {0}
    for vector in vectors:
        values |= {value ^ vector for value in tuple(values)}
    return values


def _canonical_basis(vectors):
    """Return the unique descending-pivot RREF basis of a set of vectors."""
    rows = {}
    for vector in vectors:
        value = vector
        for bit in range(29, -1, -1):
            if not (value >> bit) & 1:
                continue
            if bit in rows:
                value ^= rows[bit]
            else:
                rows[bit] = value
                for pivot, row in tuple(rows.items()):
                    if pivot != bit and (row >> bit) & 1:
                        rows[pivot] = row ^ value
                break
    return [rows[bit] for bit in sorted(rows, reverse=True)]


def _parse(values, input_length=None):
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length != len(values)
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or not values
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    case_count = values[0]
    if not 1 <= case_count <= MAX_CASES:
        return None
    cases = []
    cursor = 1
    for _ in range(case_count):
        if cursor >= len(values):
            return None
        n = values[cursor]
        cursor += 1
        if not 0 <= n <= MAX_N or cursor + n > len(values):
            return None
        left = values[cursor:cursor + n]
        cursor += n
        if any(not 0 <= vector <= MAX_VECTOR for vector in left):
            return None
        if len(_span(left)) != 1 << n:
            return None

        if cursor >= len(values):
            return None
        m = values[cursor]
        cursor += 1
        if not 0 <= m <= MAX_M or cursor + m > len(values):
            return None
        right = values[cursor:cursor + m]
        cursor += m
        if any(not 0 <= vector <= MAX_VECTOR for vector in right):
            return None
        if len(_span(right)) != 1 << m:
            return None
        cases.append((left, right))
    if cursor != len(values):
        return None
    return cases


def _oracle_words(cases):
    output = []
    for left, right in cases:
        common = _span(left) & _span(right)
        basis = _canonical_basis(common)
        output.extend((len(basis), *basis))
    return output


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(status, bytes)`` for packed test cases and canonical bases."""
    if input_is_null:
        return -1, b""
    cases = _parse(values, input_length)
    if cases is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", value) for value in _oracle_words(cases))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < len(payload):
        return -2, b""
    return len(payload), payload


def validate_output(values, payload):
    """Check exact canonical RREF output against independently enumerated spans."""
    cases = _parse(values)
    if cases is None or not isinstance(payload, (bytes, bytearray)):
        return False
    expected = b"".join(struct.pack("<q", value) for value in _oracle_words(cases))
    return bytes(payload) == expected
