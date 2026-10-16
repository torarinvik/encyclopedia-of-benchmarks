"""Bounded source-faithful oracle for TheAlgorithms/R maskWords."""
from __future__ import annotations

MAX_TEXT_BYTES = 512
MAX_MASK_BYTES = 16
MAX_INPUT_LENGTH = MAX_TEXT_BYTES + MAX_MASK_BYTES + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 1447
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

_WORDS = (b"birds", b"market", b"street")
_NORMALIZED_VARIANTS = {
    b"birds", b"BIRDS", b"Birds",
    b"market", b"MARKET", b"Market",
    b"street", b"STREET", b"Street",
}


def _is_word(value: int) -> bool:
    return (48 <= value <= 57 or 65 <= value <= 90
            or 97 <= value <= 122 or value == 95)


def _split_like_r(text: bytes) -> list[bytes]:
    """Split on literal spaces, retaining leading/interior empties but not the final one."""
    if not text:
        return []
    parts: list[bytes] = []
    start = 0
    for index, value in enumerate(text):
        if value == 32:
            parts.append(text[start:index])
            start = index + 1
    if start < len(text):
        parts.append(text[start:])
    return parts


def _mask_token(token: bytes, mask: bytes) -> bytes:
    # The source lowercases only these exact standalone spellings before gsub.
    if token in _NORMALIZED_VARIANTS:
        return mask

    output = bytearray()
    position = 0
    while position < len(token):
        matched = 0
        for word in _WORDS:
            end = position + len(word)
            if (end <= len(token) and token[position:end] == word
                    and (position == 0 or not _is_word(token[position - 1]))
                    and (end == len(token) or not _is_word(token[end]))):
                matched = len(word)
                break
        if matched:
            output.extend(mask)
            position += matched
        else:
            # The pinned source removes LF only after performing gsub.
            if token[position] != 10:
                output.append(token[position])
            position += 1
    return bytes(output)


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
) -> tuple[int, bytes]:
    """Return (byte count, output bytes); invalid input is (-1, b""), short output is (-2, b"")."""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""

    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_BYTES:
        return -1, b""
    mask_length_index = 1 + text_length
    if mask_length_index >= len(values):
        return -1, b""
    mask_length = values[mask_length_index]
    if not 0 <= mask_length <= MAX_MASK_BYTES:
        return -1, b""
    if len(values) != mask_length_index + 1 + mask_length:
        return -1, b""

    text_values = values[1:mask_length_index]
    mask_values = values[mask_length_index + 1:]
    if any(not 1 <= value <= 127 for value in text_values):
        return -1, b""
    if any(not 32 <= value <= 126 or value == 92 for value in mask_values):
        return -1, b""

    text = bytes(text_values)
    mask = bytes(mask_values)
    output = b" ".join(_mask_token(token, mask) for token in _split_like_r(text))
    if len(output) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return -1, b""
        if output_capacity < len(output):
            return -2, b""
    return len(output), output
