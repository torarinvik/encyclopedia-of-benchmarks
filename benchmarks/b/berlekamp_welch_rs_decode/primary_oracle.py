"""Berlekamp-Welch decoding over the small prime field GF(7)."""

from __future__ import annotations

from collections.abc import Sequence

FIELD = 7
MAX_N = 7
MAX_K = 3
MAX_T = 2
MAX_VALID_INPUT_LENGTH = 3 + MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 343
WORKSPACE_BYTES = 1024


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, k, errors = values[:3]
    if (not 2 <= n <= MAX_N or not 1 <= k <= min(MAX_K, n)
            or not 0 <= errors <= MAX_T or 2 * errors > n - k
            or len(values) != 3 + n
            or any(not 0 <= symbol < FIELD for symbol in values[3:])):
        return None
    return n, k, errors, tuple(values[3:])


def _solve_homogeneous(matrix: list[list[int]], variable_count: int):
    """Return one deterministic nonzero null vector, or None for a trivial kernel."""
    pivot_columns: list[int] = []
    pivot_row = 0
    row_count = len(matrix)
    for column in range(variable_count):
        found = next((r for r in range(pivot_row, row_count)
                      if matrix[r][column] % FIELD), None)
        if found is None:
            continue
        matrix[pivot_row], matrix[found] = matrix[found], matrix[pivot_row]
        inverse = pow(matrix[pivot_row][column], FIELD - 2, FIELD)
        matrix[pivot_row] = [(value * inverse) % FIELD
                             for value in matrix[pivot_row]]
        for r in range(row_count):
            if r == pivot_row:
                continue
            factor = matrix[r][column] % FIELD
            if factor:
                matrix[r] = [(left - factor * right) % FIELD
                             for left, right in zip(matrix[r], matrix[pivot_row])]
        pivot_columns.append(column)
        pivot_row += 1
        if pivot_row == row_count:
            break

    free_columns = [column for column in range(variable_count)
                    if column not in pivot_columns]
    if not free_columns:
        return None
    free_column = free_columns[0]
    solution = [0] * variable_count
    solution[free_column] = 1
    for r, pivot_column in enumerate(pivot_columns):
        solution[pivot_column] = (-matrix[r][free_column]) % FIELD
    return solution


def _trim(polynomial: list[int]) -> list[int]:
    while len(polynomial) > 1 and polynomial[-1] % FIELD == 0:
        polynomial.pop()
    return [coefficient % FIELD for coefficient in polynomial]


def _divide_polynomials(numerator: list[int], denominator: list[int]):
    remainder = _trim(numerator.copy())
    divisor = _trim(denominator.copy())
    if divisor == [0]:
        return None
    quotient = [0] * max(1, len(remainder) - len(divisor) + 1)
    inverse_lead = pow(divisor[-1], FIELD - 2, FIELD)
    while remainder != [0] and len(remainder) >= len(divisor):
        shift = len(remainder) - len(divisor)
        factor = remainder[-1] * inverse_lead % FIELD
        quotient[shift] = factor
        for j, coefficient in enumerate(divisor):
            remainder[shift + j] = (remainder[shift + j]
                                    - factor * coefficient) % FIELD
        remainder = _trim(remainder)
    if remainder != [0]:
        return None
    return _trim(quotient)


def _encode(coefficients: Sequence[int], k: int) -> int:
    code = 1
    place = 1
    for i in range(k):
        code += (coefficients[i] if i < len(coefficients) else 0) * place
        place *= FIELD
    return code


def _decode(n: int, k: int, errors: int, received: Sequence[int]) -> int:
    q_count = k + errors
    e_count = errors + 1
    variable_count = q_count + e_count
    matrix: list[list[int]] = []
    for x, symbol in enumerate(received):
        powers = [1]
        for _ in range(max(q_count, e_count) - 1):
            powers.append(powers[-1] * x % FIELD)
        matrix.append([*(powers[j] for j in range(q_count)),
                       *((-symbol * powers[j]) % FIELD for j in range(e_count))])

    solution = _solve_homogeneous(matrix, variable_count)
    if solution is None:
        return 0
    numerator = solution[:q_count]
    locator = solution[q_count:]
    if not any(locator):
        return 0
    coefficients = _divide_polynomials(numerator, locator)
    if coefficients is None or len(coefficients) > k:
        return 0
    coefficients += [0] * (k - len(coefficients))
    mismatches = 0
    for x, symbol in enumerate(received):
        value = 0
        for coefficient in reversed(coefficients):
            value = (value * x + coefficient) % FIELD
        mismatches += value != symbol
    return _encode(coefficients, k) if mismatches <= errors else 0


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, k, errors, received = parsed
    return _decode(n, k, errors, received)
