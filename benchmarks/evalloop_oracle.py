"""Independent fast oracle for the pinned Misc/evalloop command stream."""
from __future__ import annotations

MIN_PASSES = 0
MAX_PASSES = 1_000
MAX_OUTPUT_BYTES = 14
SOURCE_DEFAULT_PASSES = 100_000
SOURCE_BUFFER_SIZE = 2_048
UINT32_MASK = (1 << 32) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2

# 2,047 commands are 66 complete 1..31 cycles plus one additional 1.
SUM_PER_PASS = 66 * sum(range(1, 32)) + 1


def expected_output(passes: int) -> tuple[int, bytes]:
    """Return the source-style ``Sum: N\n`` output for bounded passes."""
    if type(passes) is not int or not MIN_PASSES <= passes <= MAX_PASSES:
        return INVALID_RESULT, b""
    total = (passes * SUM_PER_PASS) & UINT32_MASK
    output = f"Sum: {total}\n".encode("ascii")
    return len(output), output
