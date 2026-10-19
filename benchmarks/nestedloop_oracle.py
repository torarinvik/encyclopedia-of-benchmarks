"""Independent oracle for the bounded Shootout nestedloop benchmark."""

MAX_N = 15
INVALID_RESULT = -1


def expected_result(n: int) -> int:
    if type(n) is not int or n < 0 or n > MAX_N:
        return INVALID_RESULT
    return n**6
