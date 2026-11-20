"""Bottom-up merge reference for the bounded polyphase merge-sort profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 256
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1
RUN_SIZE = 8
MAX_INITIAL_RUNS = 32
MAX_RUN_DESCRIPTORS_PER_TAPE = 34
MAX_INITIAL_TAPE_QUOTA = 21
MAX_TOTAL_INITIAL_TAPE_SLOTS = 34
MAX_PHASES = 7
MAX_DUMMY_RUNS = 12
MAX_WORKSPACE_BYTES = 7008


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not MIN_I64 <= value <= MAX_I64
                   for value in values)):
        raise ValueError("polyphase merge sort expects at most 256 signed 64-bit integers")
    source = list(values)
    target = [0] * len(source)
    width = 1
    while width < len(source):
        for start in range(0, len(source), 2 * width):
            middle = min(start + width, len(source))
            end = min(start + 2 * width, len(source))
            left, right, output = start, middle, start
            while left < middle and right < end:
                if source[left] <= source[right]:
                    target[output] = source[left]
                    left += 1
                else:
                    target[output] = source[right]
                    right += 1
                output += 1
            while left < middle:
                target[output] = source[left]
                left += 1
                output += 1
            while right < end:
                target[output] = source[right]
                right += 1
                output += 1
        source, target = target, source
        width *= 2
    return source
