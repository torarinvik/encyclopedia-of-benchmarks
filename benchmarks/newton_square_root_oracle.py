"""Independent exact oracle for the bounded integer Newton benchmark."""

import math
import random

MAX_INPUT = (1 << 62) - 1


def expected_result(value: int) -> int:
    # No logarithm or Newton iteration: the benchmark's stopping condition
    # identifies exactly the floor of the nonnegative integer square root.
    return math.isqrt(value) if 0 <= value <= MAX_INPUT else -1


def boundary_inputs() -> set[int]:
    values = set(range(-8, 4097))
    values.update((-(1 << 63), (1 << 63) - 1, MAX_INPUT, MAX_INPUT + 1))
    for exponent in range(63):
        power = 1 << exponent
        values.update((power - 1, power, power + 1))
    rng = random.Random(20261111)
    for _ in range(4096):
        values.add(rng.randrange(0, MAX_INPUT + 1))
        root = rng.randrange(0, 1 << 31)
        square = root * root
        values.update((square - 1, square, square + 1))
    return values
