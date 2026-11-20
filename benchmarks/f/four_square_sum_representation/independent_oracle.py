"""Pair-sum-index reference for the four-square decomposition profile."""

from .primary_oracle import BASE, MAX_N


def expected_result(values: list[int], *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    length = len(values) if input_length is None else input_length
    if input_is_null or length != 1 or len(values) != 1:
        return -1
    n = values[0]
    if not 0 <= n <= MAX_N:
        return -1

    # Build each unordered pair once, then query the complementary pair sum.
    by_sum: dict[int, list[tuple[int, int]]] = {}
    for high in range(BASE - 1, -1, -1):
        for low in range(high, -1, -1):
            total = high * high + low * low
            if total <= n:
                by_sum.setdefault(total, []).append((high, low))

    for a in range(BASE - 1, -1, -1):
        for b in range(a, -1, -1):
            left_sum = a * a + b * b
            if left_sum > n:
                continue
            right_pairs = by_sum.get(n - left_sum, ())
            for c, d in right_pairs:
                if c <= b:
                    return (((a * BASE) + b) * BASE + c) * BASE + d
    return -2
