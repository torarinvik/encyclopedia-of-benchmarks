"""Runtime oracle for the bounded naive case-sensitive string search."""

MAX_INPUT_LENGTH = 130
MAX_TEXT_LENGTH = 64
MAX_PATTERN_LENGTH = 64


def expected_result(values: list[int]) -> int:
    if (len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_TEXT_LENGTH):
        return -1
    text_length = values[0]
    offset = text_length + 1
    if len(values) < offset + 1:
        return -1
    pattern_length = values[offset]
    if (type(pattern_length) is not int or not 1 <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != offset + pattern_length + 1
            or pattern_length > text_length):
        return -1
    text = values[1:offset]
    pattern = values[offset + 1:]
    if any(type(x) is not int or not 0 <= x <= 127 for x in text + pattern):
        return -1
    for start in range(text_length - pattern_length + 1):
        j = 0
        while j < pattern_length and text[start + j] == pattern[j]:
            j += 1
        if j == pattern_length:
            return start
    return -1
