"""Oracle matching the pinned Dart repeated-multiplication pow function."""
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1e300

def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return INVALID_RESULT
    if any(type(x) is not int for x in values):
        return INVALID_RESULT
    base, exponent = values
    if abs(base) > 1000 or not -8 <= exponent <= 12:
        return INVALID_RESULT
    result = 1.0
    for _ in range(1, exponent + 1):
        result *= base
    return result
