"""Independent ASCII oracle for the pinned Ruby remove_vowels routine."""

MAX_INPUT_LENGTH = 4096
VOWELS = frozenset(b"aeiou")


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH + 1
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    length = values[0]
    if not 0 <= length <= MAX_INPUT_LENGTH or len(values) != length + 1:
        return -1, b""
    text = values[1:]
    if any(not 0 <= value <= 127 for value in text):
        return -1, b""
    output = bytes((value + 32 if 65 <= value <= 90 else value)
                   for value in text
                   if (value + 32 if 65 <= value <= 90 else value) not in VOWELS)
    return len(output), output
