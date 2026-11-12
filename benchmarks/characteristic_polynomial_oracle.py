"""Bounded permutation-expansion oracle for characteristic polynomials."""

from itertools import permutations
import struct

MODULUS = 998_244_353
MAX_N = 8
MAX_VALID_INPUT_LENGTH = 1 + MAX_N * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)


def _multiply_polynomials(left, right):
    result = [0] * (len(left) + len(right) - 1)
    for left_degree, left_value in enumerate(left):
        for right_degree, right_value in enumerate(right):
            result[left_degree + right_degree] = (
                result[left_degree + right_degree] + left_value * right_value
            ) % MODULUS
    return result


def _permutation_sign(permutation):
    inversions = sum(
        permutation[left] > permutation[right]
        for left in range(len(permutation))
        for right in range(left + 1, len(permutation))
    )
    return -1 if inversions % 2 else 1


def _characteristic_polynomial(matrix):
    """Expand det(xI-A) by permutations; return ascending coefficients."""
    n = len(matrix)
    total = [0] * (n + 1)
    for permutation in permutations(range(n)):
        term = [1]
        for row, column in enumerate(permutation):
            constant = (-matrix[row][column]) % MODULUS
            factor = [constant, 1] if row == column else [constant]
            term = _multiply_polynomials(term, factor)
        sign = _permutation_sign(permutation)
        for degree, coefficient in enumerate(term):
            total[degree] = (total[degree] + sign * coefficient) % MODULUS
    return total


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(status, bytes)`` for ``[N, row-major matrix...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""

    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != 1 + n * n:
        return -1, b""
    entries = values[1:]
    if any(not 0 <= entry < MODULUS for entry in entries):
        return -1, b""
    matrix = [list(entries[row * n:(row + 1) * n]) for row in range(n)]
    coefficients = _characteristic_polynomial(matrix)
    encoded = b"".join(struct.pack("<q", value) for value in coefficients)

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
