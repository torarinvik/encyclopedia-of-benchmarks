"""Bounded oracle for deterministic Java-style permutation cipher encryption."""

MAX_INPUT_LENGTH = 74
MAX_TEXT_LENGTH = 64
MAX_KEY_LENGTH = 8
_MODULUS = 1_000_000_007


def expected_result(values: list[int]) -> int:
    if (len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_TEXT_LENGTH):
        return -1
    text_length = values[0]
    key_offset = text_length + 1
    if len(values) < key_offset + 1:
        return -1
    key_length = values[key_offset]
    if type(key_length) is not int or not 1 <= key_length <= MAX_KEY_LENGTH:
        return -1
    if len(values) != key_offset + key_length + 1:
        return -1
    raw = values[1:key_offset]
    key = values[key_offset + 1:]
    if any(type(value) is not int or not 0 <= value <= 127 for value in raw):
        return -1
    if any(type(value) is not int for value in key) or sorted(key) != list(range(1, key_length + 1)):
        return -1
    clean = []
    for value in raw:
        if value in (9, 10, 11, 12, 13, 32):
            continue
        clean.append(value - 32 if 97 <= value <= 122 else value)
    while len(clean) % key_length:
        clean.append(ord("X"))
    encrypted = []
    for start in range(0, len(clean), key_length):
        block = clean[start:start + key_length]
        encrypted.extend(block[position - 1] for position in key)
    result = 0
    for byte in encrypted:
        result = (result * 257 + byte) % _MODULUS
    return result
