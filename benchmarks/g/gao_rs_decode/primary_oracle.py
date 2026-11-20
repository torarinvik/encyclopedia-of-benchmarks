"""Small-field implementation of Gao's interpolation/partial-EEA decoder."""

from __future__ import annotations

from collections.abc import Sequence

FIELD = 7
MAX_N = 7
MAX_K = 3
MAX_T = 2
MAX_VALID_INPUT_LENGTH = 3 + MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 343
WORKSPACE_BYTES = 4096


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


def _trim(polynomial: list[int]) -> list[int]:
    while len(polynomial) > 1 and polynomial[-1] % FIELD == 0:
        polynomial.pop()
    return [coefficient % FIELD for coefficient in polynomial]


def _add(left: Sequence[int], right: Sequence[int]) -> list[int]:
    result = [0] * max(len(left), len(right))
    for index, coefficient in enumerate(left):
        result[index] += coefficient
    for index, coefficient in enumerate(right):
        result[index] += coefficient
    return _trim([coefficient % FIELD for coefficient in result])


def _subtract(left: Sequence[int], right: Sequence[int]) -> list[int]:
    result = [0] * max(len(left), len(right))
    for index, coefficient in enumerate(left):
        result[index] += coefficient
    for index, coefficient in enumerate(right):
        result[index] -= coefficient
    return _trim([coefficient % FIELD for coefficient in result])


def _multiply(left: Sequence[int], right: Sequence[int]) -> list[int]:
    result = [0] * max(1, len(left) + len(right) - 1)
    for left_index, left_value in enumerate(left):
        for right_index, right_value in enumerate(right):
            result[left_index + right_index] += left_value * right_value
    return _trim([coefficient % FIELD for coefficient in result])


def _divide(dividend: Sequence[int], divisor: Sequence[int]):
    remainder = _trim(list(dividend))
    denominator = _trim(list(divisor))
    if denominator == [0]:
        return None
    quotient = [0] * max(1, len(remainder) - len(denominator) + 1)
    inverse_lead = pow(denominator[-1], FIELD - 2, FIELD)
    while remainder != [0] and len(remainder) >= len(denominator):
        shift = len(remainder) - len(denominator)
        factor = remainder[-1] * inverse_lead % FIELD
        quotient[shift] = factor
        for index, coefficient in enumerate(denominator):
            remainder[shift + index] = (
                remainder[shift + index] - factor * coefficient) % FIELD
        remainder = _trim(remainder)
    return _trim(quotient), remainder


def _interpolate(received: Sequence[int]) -> list[int]:
    result = [0]
    for point, symbol in enumerate(received):
        basis = [1]
        denominator = 1
        for other in range(len(received)):
            if other == point:
                continue
            basis = _multiply(basis, [(-other) % FIELD, 1])
            denominator = denominator * (point - other) % FIELD
        scale = symbol * pow(denominator, FIELD - 2, FIELD) % FIELD
        result = _add(result, [(coefficient * scale) % FIELD
                               for coefficient in basis])
    return _trim(result)


def _vanishing_polynomial(n: int) -> list[int]:
    result = [1]
    for point in range(n):
        result = _multiply(result, [(-point) % FIELD, 1])
    return result


def _decode(n: int, k: int, errors: int, received: Sequence[int]) -> int:
    interpolation = _interpolate(received)
    if interpolation == [0]:
        return _encode([0] * k)

    # EEA rows retain r = u*G + v*I; Gao's decoder uses v for division.
    previous_remainder = _vanishing_polynomial(n)
    remainder = interpolation
    previous_u, u = [1], [0]
    previous_v, v = [0], [1]
    stop_degree = (n + k - 1) // 2
    while remainder != [0] and len(remainder) - 1 > stop_degree:
        division = _divide(previous_remainder, remainder)
        if division is None:
            return 0
        quotient, next_remainder = division
        next_u = _subtract(previous_u, _multiply(quotient, u))
        next_v = _subtract(previous_v, _multiply(quotient, v))
        previous_remainder, remainder = remainder, next_remainder
        previous_u, u = u, next_u
        previous_v, v = v, next_v

    if remainder == [0]:
        return 0
    division = _divide(remainder, v)
    if division is None:
        return 0
    coefficients, residue = division
    if residue != [0] or len(coefficients) > k:
        return 0
    coefficients += [0] * (k - len(coefficients))
    mismatches = 0
    for x, symbol in enumerate(received):
        value = 0
        for coefficient in reversed(coefficients):
            value = (value * x + coefficient) % FIELD
        mismatches += value != symbol
    return _encode(coefficients) if mismatches <= errors else 0


def _encode(coefficients: Sequence[int]) -> int:
    result = 1
    place = 1
    for coefficient in coefficients:
        result += coefficient * place
        place *= FIELD
    return result


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, k, errors, received = parsed
    return _decode(n, k, errors, received)
