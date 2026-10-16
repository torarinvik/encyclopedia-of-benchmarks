"""Independent oracle for bounded, stable ASCII word deduplication."""

from __future__ import annotations

import re

MAX_INPUT_LENGTH = 4096


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return whitespace-separated distinct words in first-seen order."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH + 1
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    text_length = values[0]
    if not 0 <= text_length <= MAX_INPUT_LENGTH or len(values) != text_length + 1:
        return -1, b""
    text = values[1:]
    if any(not 0 <= value <= 127 for value in text):
        return -1, b""
    # Parameterless .NET String.Split retains empty substrings at adjacent,
    # leading, and trailing separators; StringSplitOptions.None is the default.
    words = re.split(rb"[\x09-\x0d\x20]", bytes(text))
    output = b" ".join(dict.fromkeys(words))
    return len(output), output
