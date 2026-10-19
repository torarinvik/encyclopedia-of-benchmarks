"""Independent oracle for the bounded BenchmarkGame recursive workload."""

from __future__ import annotations

from functools import lru_cache

MIN_N = 0
MAX_N = 10
MAX_OUTPUT_BYTES = 89
INVALID_RESULT = -1
OUTPUT_ERROR = -2


@lru_cache(maxsize=None)
def _takeuchi(x: int, y: int, z: int) -> int:
    if y < x:
        return _takeuchi(
            _takeuchi(x - 1, y, z),
            _takeuchi(y - 1, z, x),
            _takeuchi(z - 1, x, y),
        )
    return z


def _one_based_fibonacci(index: int) -> int:
    """Evaluate G(k), where G(0)=G(1)=1, using an iterative oracle."""
    previous, current = 1, 1
    for _ in range(index):
        previous, current = current, previous + current
    return previous


def expected_output(n: int) -> tuple[int, bytes]:
    """Return the complete five-line output for one bounded source parameter."""
    if type(n) is not int or not MIN_N <= n <= MAX_N:
        return INVALID_RESULT, b""

    ackermann = 2 ** (n + 4) - 3  # A(3, n+1)
    fib_float = _one_based_fibonacci(28 + n)
    takeuchi = _takeuchi(3 * n, 2 * n, n)
    fib_integer = _one_based_fibonacci(3)
    takeuchi_float = _takeuchi(3, 2, 1)
    output = (
        f"Ack(3,{n + 1}): {ackermann}\n"
        f"Fib({28 + n}.0): {fib_float}.0\n"
        f"Tak({3 * n},{2 * n},{n}): {takeuchi}\n"
        f"Fib(3): {fib_integer}\n"
        f"Tak(3.0,2.0,1.0): {takeuchi_float}.0\n"
    ).encode("ascii")
    return len(output), output
