"""Runtime oracle for max-of-minimum values over every window size."""
import struct

MAX_INPUT_LENGTH = 257
MAX_VECTOR_LENGTH = 256


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -2, b""
    n, *array = values
    if not 1 <= n <= MAX_VECTOR_LENGTH or len(array) != n or any(not 0 <= x <= 1_000_000 for x in array):
        return -2, b""
    left = [-1] * n
    right = [n] * n
    stack: list[int] = []
    for i, value in enumerate(array):
        while stack and array[stack[-1]] >= value:
            stack.pop()
        if stack:
            left[i] = stack[-1]
        stack.append(i)
    stack.clear()
    for i in range(n - 1, -1, -1):
        while stack and array[stack[-1]] >= array[i]:
            stack.pop()
        if stack:
            right[i] = stack[-1]
        stack.append(i)
    answer = [0] * (n + 1)
    for i, value in enumerate(array):
        width = right[i] - left[i] - 1
        answer[width] = max(answer[width], value)
    for width in range(n - 1, 0, -1):
        answer[width] = max(answer[width], answer[width + 1])
    output = b"".join(struct.pack("<q", answer[k]) for k in range(1, n + 1))
    return n, output
