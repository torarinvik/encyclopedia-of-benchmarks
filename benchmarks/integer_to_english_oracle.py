"""Independent byte-output oracle for Java integer-to-English conversion."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
MAX_OUTPUT_BYTES = 128
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2

_SMALL = (
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen", "Twenty",
)
_TENS = ("", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety")
_SCALES = ("", "Thousand", "Million", "Billion")


def _group_words(value: int) -> str:
    words: list[str] = []
    hundreds, remainder = divmod(value, 100)
    if hundreds:
        words.extend((_SMALL[hundreds], "Hundred"))
    if remainder <= 20:
        if remainder:
            words.append(_SMALL[remainder])
    elif remainder % 10 == 0:
        words.append(_TENS[remainder // 10])
    else:
        words.extend((_TENS[remainder // 10], _SMALL[remainder % 10]))
    return " ".join(words)


def _integer_words(value: int) -> bytes:
    if value < 0:
        return b""
    if value == 0:
        return b"Zero"
    groups: list[int] = []
    while value:
        value, group = divmod(value, 1000)
        groups.append(group)
    words: list[str] = []
    for index in range(len(groups) - 1, -1, -1):
        if groups[index]:
            chunk = _group_words(groups[index])
            if index:
                chunk += " " + _SCALES[index]
            words.append(chunk)
    return " ".join(words).encode("ascii")


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    """Return the source text as ASCII bytes and its output-buffer result code."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or len(values) != 1):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    value = values[0]
    if not I32_MIN <= value <= I32_MAX:
        return INVALID_RESULT, b""
    output = _integer_words(value)
    if capacity is not None and len(output) > capacity:
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
