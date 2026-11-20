"""Independent O(N) recurrence and tiny direct-elimination oracle."""

from __future__ import annotations


def josephus_linear(values: list[int]) -> int:
    if len(values) != 2:
        return -1
    n, k = values
    if not (1 <= n <= 1_000_000 and 1 <= k <= 32):
        return -1
    survivor = 0
    for size in range(1, n + 1):
        survivor = (survivor + k % size) % size
    return survivor


def josephus_simulated(n: int, k: int) -> int:
    """List elimination for independent checks on small fixture sizes."""
    if not (1 <= n <= 256 and 1 <= k <= 32):
        raise ValueError("simulation is limited to small valid inputs")
    circle = list(range(n))
    cursor = 0
    while len(circle) > 1:
        cursor = (cursor + k - 1) % len(circle)
        circle.pop(cursor)
    return circle[0]
