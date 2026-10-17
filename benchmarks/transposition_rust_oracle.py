"""Independent oracle for the pinned Rust multi-key transposition cipher."""

from __future__ import annotations

OFFSET = 14695981039346656037
PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
MAX_KEYS = 4
MAX_KEY_LENGTH = 32
MAX_MESSAGE_LENGTH = 256
MAX_INPUT_LENGTH = 3 + MAX_KEYS + MAX_KEYS * MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH


def _feed(hash_value: int, value: int, width: int) -> int:
    for shift in range(0, width * 8, 8):
        hash_value = ((hash_value ^ ((value >> shift) & 0xFF)) * PRIME) & MASK64
    return hash_value


def _hash_output(text: str) -> int:
    digest = _feed(OFFSET, len(text), 8)
    for char in text:
        digest = _feed(digest, ord(char), 4)
    return digest & MASK63


def _column_order(key: str) -> list[int]:
    return sorted(range(len(key)), key=lambda index: (key[index], index))


def _encrypt(text: str, key: str) -> str:
    order = _column_order(key)
    columns = [text[column::len(key)] for column in range(len(key))]
    ciphertext = "".join(columns[column] for column in order)
    group_size = (len(text) + len(key) - 1) // len(key)
    return " ".join(ciphertext[start:start + group_size]
                    for start in range(0, len(ciphertext), group_size))


def _decrypt(text: str, key: str) -> str:
    order = _column_order(key)
    key_length = len(key)
    short_length, longer_columns = divmod(len(text), key_length)
    columns = [""] * key_length
    cursor = 0
    for column in order:
        column_length = short_length + (1 if column < longer_columns else 0)
        columns[column] = text[cursor:cursor + column_length]
        cursor += column_length
    return "".join(columns[column][row]
                   for row in range(short_length + (1 if longer_columns else 0))
                   for column in range(key_length)
                   if row < len(columns[column]))


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or
            not 2 <= len(values) <= MAX_INPUT_LENGTH or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return -1

    mode, key_count = values[:2]
    if mode not in (0, 1) or not 1 <= key_count <= MAX_KEYS:
        return -1

    cursor = 2
    keys: list[str] = []
    for _ in range(key_count):
        if cursor >= len(values):
            return -1
        key_length = values[cursor]
        cursor += 1
        if not 1 <= key_length <= MAX_KEY_LENGTH or cursor + key_length > len(values):
            return -1
        key_bytes = values[cursor:cursor + key_length]
        if any(not (65 <= byte <= 90 or 97 <= byte <= 122) for byte in key_bytes):
            return -1
        keys.append("".join(chr(byte).upper() for byte in key_bytes))
        cursor += key_length

    if cursor >= len(values):
        return -1
    message_length = values[cursor]
    cursor += 1
    if (not 1 <= message_length <= MAX_MESSAGE_LENGTH or
            cursor + message_length != len(values)):
        return -1
    message_bytes = values[cursor:]
    if any(not 0 <= byte <= 127 for byte in message_bytes):
        return -1

    text = "".join(chr(byte).upper() for byte in message_bytes
                   if 65 <= byte <= 90 or 97 <= byte <= 122)
    if len(text) < max(map(len, keys)):
        return -1

    if mode == 0:
        for key in keys:
            text = "".join(char for char in text if "A" <= char <= "Z")
            text = _encrypt(text, key)
    else:
        for key in reversed(keys):
            text = "".join(char for char in text if "A" <= char <= "Z")
            text = _decrypt(text, key)
    return _hash_output(text)
