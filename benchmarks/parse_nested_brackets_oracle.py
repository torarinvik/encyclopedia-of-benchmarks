"""Runtime oracle for the bounded nested-angle-bracket parser."""

MAX_INPUT_LENGTH = 129
MAX_TEXT_LENGTH = 128
_MODULUS = 1_000_000_007


def expected_result(values: list[int]) -> int:
    if (len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_TEXT_LENGTH
            or len(values) != values[0] + 1):
        return -1
    raw = values[1:]
    if any(type(byte) is not int or not 0 <= byte <= 127 for byte in raw):
        return -1
    text = bytes(raw)
    depth = 0
    for byte in text:
        if byte == ord('<'):
            depth += 1
        elif byte == ord('>'):
            depth -= 1
            if depth < 0:
                return -1
    if depth != 0:
        return -1
    result = 0

    def scan(lo: int, hi: int) -> None:
        nonlocal result
        depth = 0
        begin = 0
        for index in range(lo, hi):
            if text[index] == ord('<'):
                if depth == 0:
                    begin = index
                depth += 1
            elif text[index] == ord('>'):
                depth -= 1
                if depth == 0:
                    for char in text[begin:index + 1]:
                        result = (result * 257 + char + 1) % _MODULUS
                    scan(begin + 1, index)
    scan(0, len(text))
    return result
