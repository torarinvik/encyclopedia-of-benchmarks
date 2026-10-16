"""Shared bounded oracle for the pinned simple keyword cipher."""

MAX_KEY_LENGTH = 64
MAX_MESSAGE_LENGTH = 256
MAX_INPUT_LENGTH = 2 + MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

def cipher_map(key):
    unique = []
    for value in key:
        upper = value - 32 if 97 <= value <= 122 else value
        if upper not in unique:
            unique.append(upper)
    return unique + [letter for letter in range(65, 91) if letter not in unique]

def expected_output(values, decipher=False, capacity=None):
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    key_length, message_length = values[:2]
    if (not 0 <= key_length <= MAX_KEY_LENGTH or not 0 <= message_length <= MAX_MESSAGE_LENGTH
            or len(values) != 2 + key_length + message_length):
        return -1, b""
    key = values[2:2 + key_length]
    message = values[2 + key_length:]
    if any(not (65 <= value <= 90 or 97 <= value <= 122) for value in key):
        return -1, b""
    if any(not 0 <= value <= 127 for value in message):
        return -1, b""
    mapping = cipher_map(key)
    if decipher:
        mapping = [mapping.index(letter) + 65 for letter in range(65, 91)]
    output = bytearray()
    for value in message:
        upper = value - 32 if 97 <= value <= 122 else value
        output.append(mapping[upper - 65] if 65 <= upper <= 90 else upper)
    output = bytes(output)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
