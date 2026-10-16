"""Oracle for a fixed 5x5 Polybius square backed by the pinned Go API."""

MAX_INPUT_LENGTH = 65
MAX_TEXT_BYTES = 64
MAX_OUTPUT_BYTES = 128
ALPHABET = "ABCDEFGHIKLMNOPQRSTUVWXYZ"


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return -1, b""
    count, text = values[0], values[1:]
    if type(count) is not int or not 0 <= count <= MAX_TEXT_BYTES or len(text) != count:
        return -1, b""
    out = bytearray()
    for value in text:
        if not 0 <= value <= 127:
            return -1, b""
        if 97 <= value <= 122:
            value -= 32
        if value < 65 or value > 90 or value == 74:
            return -1, b""
        index = ALPHABET.index(chr(value))
        out.extend((65 + index // 5, 65 + index % 5))
    return len(out), bytes(out)
