"""Oracle for the bounded JavaScript factorial/permutation/combination module."""

MAX_INPUT_LENGTH = 3
MAX_N = 18


def expected_result(values):
    if (not isinstance(values, (tuple, list)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return -1
    operation, n, r = values
    if operation not in (0, 1, 2) or not 0 <= n <= MAX_N:
        return -1
    if operation == 0:
        return factorial(n)
    if not 0 <= r <= n:
        return -1
    if operation == 1:
        result = 1
        for value in range(n - r + 1, n + 1):
            result *= value
        return result
    r = min(r, n - r)
    result = 1
    for index in range(1, r + 1):
        result = result * (n - r + index) // index
    return result


def factorial(n):
    result = 1
    for value in range(2, n + 1):
        result *= value
    return result
