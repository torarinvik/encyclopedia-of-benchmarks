"""Oracle for the bounded, deterministic Fermat-prime checker contract."""

from __future__ import annotations

MAX_NUMBER = 1_000_000
MAX_CHECKS = 64
INVALID_RESULT = -1


class _DotNetRandom0:
    """Legacy System.Random subtractive generator used by the pinned C# source."""

    def __init__(self) -> None:
        self._seed = [0] * 56
        mj = 161803398
        self._seed[55] = mj
        mk = 1
        for i in range(1, 55):
            index = (21 * i) % 55
            self._seed[index] = mk
            mk = mj - mk
            if mk < 0:
                mk += 2_147_483_647
            mj = self._seed[index]
        for _ in range(4):
            for i in range(1, 56):
                self._seed[i] -= self._seed[1 + (i + 30) % 55]
                if self._seed[i] < 0:
                    self._seed[i] += 2_147_483_647
        self._next = 0
        self._next_p = 21

    def _sample(self) -> float:
        self._next += 1
        if self._next >= 56:
            self._next = 1
        self._next_p += 1
        if self._next_p >= 56:
            self._next_p = 1
        result = self._seed[self._next] - self._seed[self._next_p]
        if result == 2_147_483_647:
            result -= 1
        if result < 0:
            result += 2_147_483_647
        self._seed[self._next] = result
        return result * (1.0 / 2_147_483_647)

    def next(self, minimum: int, maximum: int) -> int:
        return int(self._sample() * (maximum - minimum)) + minimum


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT
    number, times_to_check = values
    if not 2 <= number <= MAX_NUMBER or not 2 <= times_to_check <= MAX_CHECKS:
        return INVALID_RESULT

    rng = _DotNetRandom0()
    exponent = number - 1
    for _ in range(times_to_check - 1):
        base = rng.next(1, number)
        if pow(base, exponent, number) != 1:
            return 0
    return 1
