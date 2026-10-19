"""Independent oracle for the bounded Shootout fib2 benchmark."""

MAX_N = 30
INVALID_RESULT = -1


def expected_result(n: int) -> int:
    if type(n) is not int or not 0 <= n <= MAX_N:
        return INVALID_RESULT
    previous, current = 1, 1
    for _ in range(2, n + 1):
        previous, current = current, previous + current
    return previous if n < 2 else current
