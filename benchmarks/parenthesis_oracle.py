"""Oracle for the Go parentheses-only counter."""

MAX_TEXT_BYTES = 128
MAX_INPUT_LENGTH = 129


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1
    count = values[0]
    if not 0 <= count <= MAX_TEXT_BYTES or len(values) != count + 1:
        return -1
    balance = 0
    for value in values[1:]:
        if not 0 <= value <= 127:
            return -1
        if value == 40:
            balance += 1
        elif value == 41:
            balance -= 1
            if balance < 0:
                return 0
    return int(balance == 0)
