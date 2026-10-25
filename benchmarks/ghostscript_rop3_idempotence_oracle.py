"""Independent oracle for Ghostscript's source-defined ROP3 predicate."""

MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def expected_result(values):
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT
    if len(values) != 1 or not 0 <= values[0] <= 255:
        return INVALID_RESULT
    code = values[0]
    # Source macro !(op & ~(op << 1) & 0xaa), expanded over its four
    # destination-mask positions without using the macro expression.
    for odd_position in (1, 3, 5, 7):
        if ((code >> odd_position) & 1) and not ((code >> (odd_position - 1)) & 1):
            return 0
    return 1
