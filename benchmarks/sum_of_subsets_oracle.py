"""Bounded, source-ordered oracle for sum of subsets."""

import struct


MIN_N = 0
MAX_N = 10
MAX_TARGET = 250
MAX_VALUE = 50
MAX_SUBSETS = 1 << MAX_N
MAX_INPUT_LENGTH = MAX_N + 2
MAX_OUTPUT_BYTES = 8 + MAX_SUBSETS * 8 * (1 + MAX_N)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values, output_capacity=MAX_OUTPUT_BYTES):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""

    n, target = values[:2]
    if (not MIN_N <= n <= MAX_N or len(values) != n + 2
            or not 0 <= target <= MAX_TARGET
            or any(not 0 <= value <= MAX_VALUE for value in values[2:])):
        return -1, b""

    numbers = values[2:]
    solutions = []

    def visit(index, path, remaining):
        current = sum(path)
        if current > target or remaining + current < target:
            return
        if current == target:
            solutions.append(path[:])
            return
        for position in range(index, n):
            visit(position + 1, path + [numbers[position]],
                  remaining - numbers[position])

    visit(0, [], sum(numbers))

    encoded = bytearray(struct.pack("<q", len(solutions)))
    for solution in solutions:
        encoded.extend(struct.pack("<q", len(solution)))
        for value in solution:
            encoded.extend(struct.pack("<q", value))
    output = bytes(encoded)

    if output_capacity < len(output):
        return -2, b""
    return len(output), output
