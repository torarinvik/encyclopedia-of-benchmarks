"""Independent bounded oracle for the pinned Python isomorphism check."""

MAX_CODEPOINTS_PER_STRING = 8
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_CODEPOINTS_PER_STRING
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 2  # admit both strings at length 9


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1
    source_length, target_length = values[:2]
    if (not 0 <= source_length <= MAX_CODEPOINTS_PER_STRING
            or not 0 <= target_length <= MAX_CODEPOINTS_PER_STRING
            or len(values) != 2 + source_length + target_length):
        return -1
    source = values[2:2 + source_length]
    target = values[2 + source_length:]
    if any(codepoint < 0 or codepoint > 127 for codepoint in source + target):
        return -1
    if source_length != target_length:
        return 0

    for index in range(source_length):
        for previous in range(index):
            if (source[index] == source[previous]) != (target[index] == target[previous]):
                return 0
    return 1
