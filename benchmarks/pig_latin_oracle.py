"""Runtime oracle for the bounded ASCII Pig Latin benchmark."""

MAX_INPUT_LENGTH = 65
MAX_WORD_BYTES = 64
VOWELS = b"aeiou"


def expected_output(values):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_WORD_BYTES or len(values) != count + 1:
        return -1, b""
    word = bytearray()
    for value in values[1:]:
        if not 0 <= value <= 127:
            return -1, b""
        if 65 <= value <= 90:
            value += 32
        if not 97 <= value <= 122:
            return -1, b""
        word.append(value)
    if not word:
        return 0, b""
    try:
        pivot = next(index for index, char in enumerate(word) if char in VOWELS)
    except StopIteration:
        return -1, b""
    if pivot == 0:
        result = bytes(word) + b"way"
    else:
        result = bytes(word[pivot:] + word[:pivot]) + b"ay"
    return len(result), result
