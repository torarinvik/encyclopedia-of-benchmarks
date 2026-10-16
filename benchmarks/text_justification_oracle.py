"""Bounded reference for the pinned greedy text-justification routine."""

from __future__ import annotations

MAX_WIDTH = 64
MAX_TEXT_BYTES = 512
MAX_WORDS = 64
MAX_INPUT_LENGTH = 2 + MAX_TEXT_BYTES + 1  # one extra slot reaches malformed-length handling
MAX_OUTPUT_BYTES = MAX_WORDS * MAX_WIDTH + MAX_WORDS
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _justify_line(words: list[bytes], letters: int, width: int) -> bytes:
    gap_count = len(words) - 1
    if gap_count == 0:
        return words[0] + b" " * (width - letters)

    total_spaces = width - letters
    base, extra = divmod(total_spaces, gap_count)
    parts: list[bytes] = []
    for index, word in enumerate(words[:-1]):
        parts.append(word)
        parts.append(b" " * (base + (index < extra)))
    parts.append(words[-1])
    return b"".join(parts)


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return byte length and newline-separated justified lines, or a status."""
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    width, text_length = values[:2]
    if (not 1 <= width <= MAX_WIDTH or not 0 <= text_length <= MAX_TEXT_BYTES
            or len(values) != 2 + text_length):
        return INVALID_RESULT, b""

    text_bytes = values[2:]
    if any(value != 32 and not 33 <= value <= 126 for value in text_bytes):
        return INVALID_RESULT, b""
    words = [word for word in bytes(text_bytes).split(b" ") if word]
    if len(words) > MAX_WORDS or any(len(word) > width for word in words):
        return INVALID_RESULT, b""

    lines: list[bytes] = []
    line: list[bytes] = []
    letter_count = 0
    for word in words:
        if letter_count + len(word) + len(line) <= width:
            line.append(word)
            letter_count += len(word)
        else:
            lines.append(_justify_line(line, letter_count, width))
            line = [word]
            letter_count = len(word)

    trailing_spaces = width - letter_count - len(line)
    lines.append(b" ".join(line) + b" " * (trailing_spaces + 1))
    output = b"\n".join(lines)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(output):
            return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
