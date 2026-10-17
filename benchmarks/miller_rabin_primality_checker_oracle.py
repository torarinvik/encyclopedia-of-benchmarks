"""Oracle for the bounded C# Miller-Rabin primality checker contract."""

from __future__ import annotations

MAX_VALID_INPUT_VALUES = 3
MAX_INPUT_LENGTH = 4  # one extra value is parseable for wrong-length rejection
MAX_N = 2_147_483_647
MAX_ROUNDS = 64
MAX_SEED = 2_147_483_647
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1
GOLDEN = 0x9E3779B97F4A7C15


class _SplitMix64:
    def __init__(self, seed: int) -> None:
        self.state = seed & MASK64

    def next_u64(self) -> int:
        self.state = (self.state + GOLDEN) & MASK64
        value = self.state
        value = ((value ^ (value >> 30)) * 0xBF58476D1CE4E5B9) & MASK64
        value = ((value ^ (value >> 27)) * 0x94D049BB133111EB) & MASK64
        return value ^ (value >> 31)

    def bounded(self, bound: int) -> int:
        """Return an unbiased value in [0, bound), consuming a word for bound 1."""
        threshold = (1 << 64) % bound
        while True:
            value = self.next_u64()
            if value >= threshold:
                return value % bound


def _probably_prime(n: int, rounds: int, seed: int) -> int:
    rng = _SplitMix64(seed)
    witness = 2 + rng.bounded(n - 4)

    odd_part = n - 1
    power_of_two = 0
    while odd_part % 2 == 0:
        power_of_two += 1
        odd_part //= 2

    for _ in range(rounds):
        value = pow(witness, odd_part, n)
        if value == 1 or value == n - 1:
            continue

        remaining = power_of_two - 1
        while remaining > 0 and value != n - 1:
            remaining -= 1
            value = value * value % n

        if value != n - 1:
            return 0

    return 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the source-normalized probable-prime result, or -1 if invalid."""
    if (not isinstance(values, (list, tuple))
            or len(values) != MAX_VALID_INPUT_VALUES
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT

    n, rounds, seed = values
    if (n < 5 or n > MAX_N or n % 2 == 0
            or rounds < 1 or rounds > MAX_ROUNDS
            or seed < 0 or seed > MAX_SEED):
        return INVALID_RESULT

    return _probably_prime(n, rounds, seed)
