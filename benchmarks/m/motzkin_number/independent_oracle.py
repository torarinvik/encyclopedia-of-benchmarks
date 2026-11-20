"""Binomial-Catalan sum reference for bounded Motzkin numbers."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import INVALID_RESULT, MAX_N, _parse


def _binomial(n: int, k: int) -> int:
    k = min(k, n - k)
    value = 1
    for step in range(1, k + 1):
        value = value * (n - k + step) // step
    return value


def _catalan(index: int) -> int:
    return _binomial(2 * index, index) // (index + 1)


def _binomial_catalan_sum(n: int) -> int:
    total = 0
    for index in range(n // 2 + 1):
        total += _binomial(n, 2 * index) * _catalan(index)
    return total


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return M_n from its independent binomial-Catalan representation."""
    n = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if n is None else _binomial_catalan_sum(n)
