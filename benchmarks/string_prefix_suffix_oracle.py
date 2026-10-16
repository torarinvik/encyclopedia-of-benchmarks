"""Independent contract oracle for UTF-16 string prefix/suffix checks."""

from __future__ import annotations

MAX_CODE_UNITS = 1024
MAX_INPUT_LENGTH = 2052


def expected_result(values: list[int]) -> int:
    """Return 1 for a match, 0 for no match, or -1 for malformed input."""
    if not values or len(values) > MAX_INPUT_LENGTH:
        return -1
    if len(values) < 3:
        return -1
    mode, text_count, pattern_count = values[:3]
    if type(mode) is not int or mode not in (0, 1):
        return -1
    if type(text_count) is not int or not 0 <= text_count <= MAX_CODE_UNITS:
        return -1
    if type(pattern_count) is not int or not 0 <= pattern_count <= MAX_CODE_UNITS:
        return -1
    if len(values) != 3 + text_count + pattern_count:
        return -1
    units = values[3:]
    if any(type(unit) is not int or not 0 <= unit <= 0xFFFF for unit in units):
        return -1
    text = units[:text_count]
    pattern = units[text_count:]
    if pattern_count > text_count:
        return 0
    if mode == 0:
        return int(text[:pattern_count] == pattern)
    return int(text[text_count - pattern_count :] == pattern)
