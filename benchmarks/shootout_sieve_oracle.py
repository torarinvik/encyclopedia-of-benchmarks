"""Independent output oracle for the bounded Shootout sieve profile."""

from functools import lru_cache

MAX_ITERATIONS = 64
SIEVE_LIMIT = 8192
MAX_OUTPUT_BYTES = 12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


@lru_cache(maxsize=1)
def _prime_count_through_limit() -> int:
    """Count primes by trial division, independently of the source sieve."""
    count = 0
    for candidate in range(2, SIEVE_LIMIT + 1):
        divisor = 2
        while divisor <= candidate // divisor:
            if candidate % divisor == 0:
                break
            divisor += 1
        else:
            count += 1
    return count


def expected_output(iterations: int) -> tuple[int, bytes]:
    """Return the exact bounded source stdout line or the invalid sentinel."""
    if (type(iterations) is not int
            or not 0 <= iterations <= MAX_ITERATIONS):
        return INVALID_RESULT, b""
    count = 0 if iterations == 0 else _prime_count_through_limit()
    output = f"Count: {count}\n".encode("ascii")
    return len(output), output
