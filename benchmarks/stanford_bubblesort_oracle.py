"""Independent oracle for the bounded Stanford Bubblesort output."""
from __future__ import annotations

MIN_RUNS = 1
MAX_RUNS = 100
ELEMENT_COUNT = 500
MAX_OUTPUT_BYTES = 700
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _make_input() -> tuple[list[int], int, int]:
    seed = 74755
    values: list[int] = []
    biggest = 0
    littlest = 0
    for _ in range(ELEMENT_COUNT):
        seed = (seed * 1309 + 13849) & 65535
        temp = seed
        value = temp - (temp // 100000) * 100000 - 50000
        values.append(value)
        if value > biggest:
            biggest = value
        elif value < littlest:
            littlest = value
    return values, littlest, biggest


def expected_output(runs: int) -> tuple[int, bytes]:
    """Return the source stdout prefix for one through one hundred runs.

    Every upstream pass resets the generator to the same seed and selects the
    next sorted rank. Python's independent stable sort supplies those ranks.
    """
    if type(runs) is not int or not MIN_RUNS <= runs <= MAX_RUNS:
        return INVALID_RESULT, b""
    values, littlest, biggest = _make_input()
    ordered = sorted(values)
    rows: list[str] = []
    for rank in range(runs):
        if ordered[0] != littlest or ordered[-1] != biggest:
            rows.append("Error3 in Bubble.\n")
        rows.append(f"{ordered[rank]}\n")
    output = "".join(rows).encode("ascii")
    return len(output), output
