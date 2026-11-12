"""Modular row-recurrence oracle for the bounded second-kind Stirling profile."""

MODULUS = 998_244_353
MAX_N = 16
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def stirling_row(n):
    """Return the complete row S(n, 0..n) modulo the task prime."""
    row = [0] * (n + 1)
    row[0] = 1
    for current_n in range(1, n + 1):
        for k in range(current_n, 0, -1):
            row[k] = (row[k - 1] + k * row[k]) % MODULUS
        row[0] = 0
    return row


def checksum(row):
    return sum(((k + 1) ** 3) * value for k, value in enumerate(row)) % MODULUS


def expected_result(values):
    if (not isinstance(values, (list, tuple))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or type(values[0]) is not int
            or not 0 <= values[0] <= MAX_N):
        return INVALID_RESULT
    return checksum(stirling_row(values[0]))
