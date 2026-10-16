"""Independent source-shaped oracle for the bounded Rust Gronsfeld contract."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_TEXT_LENGTH = 256
MAX_KEY_LENGTH = 64
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + MAX_KEY_LENGTH + 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return (output byte count, output bytes), or (-1, empty) if malformed."""
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    try:
        separator = values.index(0)
    except ValueError:
        return -1, b""

    text = values[:separator]
    key = values[separator + 1:]
    if (len(text) > MAX_TEXT_LENGTH or not 1 <= len(key) <= MAX_KEY_LENGTH
            or any(not 1 <= value <= 127 for value in text)
            or any(not 48 <= value <= 57 for value in key)):
        return -1, b""

    output = bytearray()
    key_index = 0
    for value in text:
        if 65 <= value <= 90:
            shift = key[key_index % len(key)] - 48
            output.append(65 + (value - 65 + shift) % 26)
            key_index += 1
        elif 97 <= value <= 122:
            shift = key[key_index % len(key)] - 48
            output.append(97 + (value - 97 + shift) % 26)
            key_index += 1
        else:
            output.append(value)
    return len(output), bytes(output)
