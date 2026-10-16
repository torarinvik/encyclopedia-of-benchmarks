"""Oracle for the bounded Java Move-to-Front transform and inverse."""

from __future__ import annotations

MAX_ALPHABET_LENGTH = 32
MAX_TEXT_LENGTH = 128
MAX_INPUT_LENGTH = 3 + MAX_ALPHABET_LENGTH + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = MAX_TEXT_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    mode, alphabet_length, text_length = values[:3]
    if (mode not in (0, 1) or not 0 <= alphabet_length <= MAX_ALPHABET_LENGTH
            or not 0 <= text_length <= MAX_TEXT_LENGTH
            or len(values) != 3 + alphabet_length + text_length):
        return -1, b""
    alphabet_values = values[3:3 + alphabet_length]
    payload = values[3 + alphabet_length:]
    if (any(not 0 <= value <= 127 for value in alphabet_values)
            or len(set(alphabet_values)) != alphabet_length):
        return -1, b""

    alphabet = list(alphabet_values)
    result: list[int] = []
    if mode == 0:
        if text_length and not alphabet:
            return -1, b""
        if any(not 0 <= value <= 127 for value in payload):
            return -1, b""
        for symbol in payload:
            try:
                index = alphabet.index(symbol)
            except ValueError:
                return -1, b""
            result.append(index)
            alphabet.insert(0, alphabet.pop(index))
    elif alphabet:
        for index in payload:
            if not 0 <= index < len(alphabet):
                return -1, b""
            result.append(alphabet[index])
            alphabet.insert(0, alphabet.pop(index))
    # The Java inverse returns an empty string before examining indices when its alphabet is empty.
    encoded = bytes(result)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
