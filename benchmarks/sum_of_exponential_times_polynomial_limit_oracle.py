"""Eulerian-polynomial oracle for the convergent infinite power sum."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998244353
MAX_DEGREE = 256
MAX_INPUT_VALUES = 2
MAX_PARSEABLE_INPUT_VALUES = 3
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int] | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return None
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if length != MAX_INPUT_VALUES or len(values) != length:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    r, degree = values
    if not 0 <= r < MODULUS or r == 1 or not 0 <= degree <= MAX_DEGREE:
        return None
    return r, degree


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return ``sum(r**i * i**d, i>=0)`` modulo 998244353, or -1."""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT
    r, degree = parsed
    inverse_denominator = pow((1 - r) % MODULUS, MODULUS - 2, MODULUS)
    if degree == 0:
        return inverse_denominator

    # Eulerian row A_degree(x), where A_0(x)=1 and
    # A_n(x)=sum_k ((n-k)A(n-1,k-1)+(k+1)A(n-1,k))x^k.
    row = [1]
    for n in range(1, degree + 1):
        next_row = [0] * (n + 1)
        for k in range(n + 1):
            if k > 0:
                next_row[k] += (n - k) * row[k - 1]
            if k < n:
                next_row[k] += (k + 1) * row[k]
            next_row[k] %= MODULUS
        row = next_row

    eulerian_value = 0
    for coefficient in reversed(row):
        eulerian_value = (eulerian_value * r + coefficient) % MODULUS
    return (r * eulerian_value % MODULUS
            * pow(inverse_denominator, degree + 1, MODULUS) % MODULUS)
