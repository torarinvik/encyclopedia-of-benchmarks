"""Independent oracle for Stanford's fixed generated-array quicksort workload."""

from __future__ import annotations

MIN_PREFIX_COUNT = 1
MAX_PREFIX_COUNT = 100
SORT_ELEMENTS = 5_000
MAX_OUTPUT_BYTES = 700
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _sorted_values() -> list[int]:
    """Generate and sort the source's 5,000 deterministic signed values."""
    state = 74_755
    values: list[int] = []
    for _ in range(SORT_ELEMENTS):
        state = (state * 1_309 + 13_849) & 0xFFFF
        # Rand() is at most 65535, so the source's /100000 term is zero.
        values.append(state - 50_000)
    return sorted(values)


def expected_output(prefix_count: int) -> tuple[int, bytes]:
    """Return the first source-printed order statistics as decimal lines."""
    if (type(prefix_count) is not int
            or not MIN_PREFIX_COUNT <= prefix_count <= MAX_PREFIX_COUNT):
        return INVALID_RESULT, b""

    values = _sorted_values()
    output = "".join(f"{value}\n" for value in values[:prefix_count]).encode("ascii")
    return len(output), output
