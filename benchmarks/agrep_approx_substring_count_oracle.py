"""Independent reference for bounded approximate substring matching."""

from __future__ import annotations


MAX_PATTERN_LENGTH = 63
MAX_TEXT_LENGTH = 4096
MAX_ERRORS = 2


def agrep_approx_substring_count(values: list[int]) -> int:
    """Count text positions with an approximate pattern match ending there."""
    if len(values) < 3:
        return -2
    pattern_length, text_length, max_errors = values[:3]
    if not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return -2
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 0 <= max_errors <= MAX_ERRORS:
        return -2
    if len(values) != 3 + pattern_length + text_length:
        return -2
    pattern = values[3 : 3 + pattern_length]
    text = values[3 + pattern_length :]
    if any(not 32 <= byte <= 126 for byte in pattern + text):
        return -2

    # row[j] is the cheapest edit cost from pattern[:j] to any suffix of the
    # text processed so far. row[0] is reset after each new byte to allow a
    # match to begin at every position.
    row = list(range(pattern_length + 1))
    matches = 0
    for byte in text:
        next_row = [0] * (pattern_length + 1)
        for j, pattern_byte in enumerate(pattern, start=1):
            next_row[j] = min(
                row[j] + 1,
                next_row[j - 1] + 1,
                row[j - 1] + (byte != pattern_byte),
            )
        row = next_row
        if row[pattern_length] <= max_errors:
            matches += 1
    return matches

