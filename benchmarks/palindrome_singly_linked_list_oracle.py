"""Runtime oracle for the optimized singly-linked-list palindrome check."""

MAX_INPUT_LENGTH = 65
MAX_COUNT = 64


def expected_result(values: list[int]) -> int:
    if (len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_COUNT
            or len(values) != values[0] + 1
            or any(type(x) is not int or not -(1 << 31) <= x < (1 << 31) for x in values[1:])):
        return -1
    items = values[1:]
    middle = (len(items) + 1) // 2
    return int(items[:middle] == list(reversed(items[len(items) - middle:])))
