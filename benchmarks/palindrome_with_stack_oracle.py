"""Runtime oracle for the bounded ASCII stack palindrome benchmark."""

MAX_INPUT_LENGTH = 129
MAX_TEXT_LENGTH = 128


def expected_result(values: list[int]) -> int:
    if (len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_TEXT_LENGTH
            or len(values) != values[0] + 1):
        return -1
    text = values[1:]
    if any(type(byte) is not int or not 0 <= byte <= 127 for byte in text):
        return -1
    lowered = bytes(byte + 32 if 65 <= byte <= 90 else byte for byte in text)
    return int(lowered == lowered[::-1])
