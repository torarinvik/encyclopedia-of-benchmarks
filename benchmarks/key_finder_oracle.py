"""Bounded oracle for the pinned JavaScript keyFinder heuristic."""

from __future__ import annotations

MAX_TEXT_LENGTH = 256
MAX_PARSEABLE_INPUT_VALUES = 258
INVALID_RESULT = -1

WORD_BANK = (
    "I ", "You ", "We ", "They ", "He ", "She ", "It ", " the ",
    "The ", " of ", " is ", "Is ", " am ", "Am ", " are ", "Are ",
    " have ", "Have ", " has ", "Has ", " may ", "May ", " be ", "Be ",
)


def _shift_ascii_letter(code: int, key: int) -> int:
    if 65 <= code <= 90:
        return 65 + (code - 65 + key) % 26
    if 97 <= code <= 122:
        return 97 + (code - 97 + key) % 26
    return code


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the first source-ordered matching shift or its ambiguous 0."""
    if (not isinstance(values, (list, tuple))
            or len(values) < 1
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    text_length = values[0]
    if text_length < 0 or text_length > MAX_TEXT_LENGTH or len(values) != text_length + 1:
        return INVALID_RESULT

    text_bytes = values[1:]
    if any(code < 32 or code > 126 or 48 <= code <= 57 for code in text_bytes):
        return INVALID_RESULT

    for key in range(26):
        shifted = "".join(chr(_shift_ascii_letter(code, key)) for code in text_bytes)
        if any(phrase in shifted for phrase in WORD_BANK):
            return key
    return 0
