"""Independent oracle for the bounded Dart character-deduplication port."""

from __future__ import annotations

MAX_INPUT_LENGTH = 4096


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return first-seen ASCII bytes, or ``(-1, b"")`` for malformed input."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH + 1
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    text_length = values[0]
    if not 0 <= text_length <= MAX_INPUT_LENGTH or len(values) != text_length + 1:
        return -1, b""
    text = values[1:]
    if any(not 0 <= value <= 127 for value in text):
        return -1, b""

    seen = bytearray(128)
    output = bytearray()
    for value in text:
        if not seen[value]:
            seen[value] = 1
            output.append(value)
    return len(output), bytes(output)
