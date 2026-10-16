"""Oracle for the pinned Python generate_rule_30 grid wrapper."""

from __future__ import annotations

MAX_WIDTH = 64
MAX_GENERATIONS = 64
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = MAX_WIDTH * MAX_GENERATIONS
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""
    width, generation_count = values
    if not 1 <= width <= MAX_WIDTH or not 1 <= generation_count <= MAX_GENERATIONS:
        return -1, b""

    current = [0] * width
    current[width // 2] = 1
    output = bytearray(current)
    for _ in range(1, generation_count):
        following = [0] * width
        for index in range(width):
            left = current[index - 1] if index > 0 else 0
            center = current[index]
            right = current[index + 1] if index + 1 < width else 0
            pattern = (left << 2) | (center << 1) | right
            following[index] = (30 >> pattern) & 1
        output.extend(following)
        current = following
    return len(output), bytes(output)
