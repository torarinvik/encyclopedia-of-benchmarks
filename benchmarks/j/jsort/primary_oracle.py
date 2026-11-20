"""Bottom-up mergesort reference for bounded signed-i64 JSort inputs."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 1024
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        raise ValueError("JSort oracle expects at most 1024 signed 64-bit integers")
    source = list(values)
    target = [0] * len(source)
    width = 1
    while width < len(source):
        for start in range(0, len(source), 2 * width):
            middle = min(start + width, len(source))
            end = min(start + 2 * width, len(source))
            left = start
            right = middle
            output = start
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
