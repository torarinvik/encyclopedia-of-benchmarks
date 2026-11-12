"""Independent rational-tail and Faulhaber identities for finite sums."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998244353
MAX_DEGREE = 32
MAX_N = 10**18
INVALID_RESULT = -1


def _read_input(values: Sequence[int] | None, input_length: int | None,
                input_is_null: bool) -> tuple[int, int, int] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != 3):
        return None
    if not isinstance(values, (list, tuple)) or len(values) != 3:
        return None
    if input_length is not None and input_length != len(values):
        return None
    for item in values:
        if type(item) is not int or item < -(1 << 63) or item >= (1 << 63):
            return None
    r, degree, n = values
    if r < 0 or r >= MODULUS or degree < 0 or degree > MAX_DEGREE:
        return None
    if n < 0 or n > MAX_N:
        return None
    return r, degree, n


def _unit_ratio_sum(degree: int, n: int) -> int:
    """Use Stirling numbers and summed falling factorials when r=1."""
    stirling = [0] * (degree + 1)
    stirling[0] = 1
    for order in range(1, degree + 1):
        for k in range(order, 0, -1):
            stirling[k] = (stirling[k - 1] + k * stirling[k]) % MODULUS
        stirling[0] = 0

    factorials = [1] * (degree + 2)
    for k in range(1, degree + 2):
        factorials[k] = factorials[k - 1] * k % MODULUS
    inverse_factorial = [1] * (degree + 2)
    inverse_factorial[-1] = pow(factorials[-1], MODULUS - 2, MODULUS)
    for k in range(degree + 1, 0, -1):
        inverse_factorial[k - 1] = inverse_factorial[k] * k % MODULUS

    answer = 0
    for k in range(degree + 1):
        falling = 1
        for offset in range(k + 1):
            falling = falling * ((n - offset) % MODULUS) % MODULUS
        choose_n = falling * inverse_factorial[k + 1] % MODULUS
        answer = (answer + stirling[k] * factorials[k] * choose_n) % MODULUS
    return answer


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return the finite weighted power sum, or -1 for an invalid frame."""
    parsed = _read_input(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT
    r, degree, n = parsed
    if r == 1:
        return _unit_ratio_sum(degree, n)

    # The finite segment is the formal infinite tail at zero minus the same
    # tail shifted by n. This uses Eulerian rows rather than block composition.
    inverse_denominator = pow((1 - r) % MODULUS, MODULUS - 2, MODULUS)
    infinite_moments = [inverse_denominator]
    eulerian_row = [1]
    inverse_power = inverse_denominator
    for order in range(1, degree + 1):
        next_row = [0] * (order + 1)
        for k in range(order + 1):
            value = 0
            if k > 0:
                value += (order - k) * eulerian_row[k - 1]
            if k < order:
                value += (k + 1) * eulerian_row[k]
            next_row[k] = value % MODULUS
        eulerian_row = next_row
        eulerian_value = 0
        for coefficient in reversed(eulerian_row):
            eulerian_value = (eulerian_value * r + coefficient) % MODULUS
        inverse_power = inverse_power * inverse_denominator % MODULUS
        infinite_moments.append(r * eulerian_value % MODULUS * inverse_power % MODULUS)

    shifted_tail = 0
    for order in range(degree + 1):
        binomial = 1
        for factor in range(1, order + 1):
            binomial = binomial * (degree - factor + 1) % MODULUS
            binomial = binomial * pow(factor, MODULUS - 2, MODULUS) % MODULUS
        index_power = pow(n % MODULUS, degree - order, MODULUS)
        term = binomial * index_power % MODULUS * infinite_moments[order] % MODULUS
        shifted_tail = (shifted_tail + term) % MODULUS

    return (infinite_moments[degree]
            - pow(r, n, MODULUS) * shifted_tail) % MODULUS


def verify_result(values: Sequence[int] | None, result: int,
                  input_length: int | None = None,
                  input_is_null: bool = False) -> bool:
    return result == expected_result(values, input_length, input_is_null)
