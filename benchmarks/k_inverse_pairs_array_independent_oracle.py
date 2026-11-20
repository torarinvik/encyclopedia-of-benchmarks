"""Direct truncated-product expansion for the Mahonian coefficients."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_N = 128
MAX_K = 512
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3


def _parse(values: Sequence[int] | None) -> tuple[int, int] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if len(values) != 2:
        return None
    n, k = values
    if not 0 <= n <= MAX_N or not 0 <= k <= MAX_K:
        return None
    return n, k


def expected_result(values: Sequence[int] | None) -> int:
    """Multiply truncated factors (1+q+...+q^(size-1)) directly."""
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, k = parsed
    if k > n * (n - 1) // 2:
        return 0

    coefficients = [0] * (k + 1)
    coefficients[0] = 1
    for size in range(1, n + 1):
        product = [0] * (k + 1)
        for degree, count in enumerate(coefficients):
            if count == 0:
                continue
            last_increment = min(size - 1, k - degree)
            for increment in range(last_increment + 1):
                target = degree + increment
                product[target] = (product[target] + count) % MODULUS
        coefficients = product
    return coefficients[k]


def enumerate_small(values: Sequence[int]) -> int | None:
    """Factorial oracle for small n, independent of coefficient DP."""
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, k = parsed
    if n > 9:
        return None
    permutation = list(range(1, n + 1))
    total = 0

    def visit(position: int) -> None:
        nonlocal total
        if position == n:
            inversions = sum(
                permutation[left] > permutation[right]
                for left in range(n)
                for right in range(left + 1, n)
            )
            if inversions == k:
                total += 1
            return
        for index in range(position, n):
            permutation[position], permutation[index] = permutation[index], permutation[position]
            visit(position + 1)
            permutation[position], permutation[index] = permutation[index], permutation[position]

    visit(0)
    return total % MODULUS
