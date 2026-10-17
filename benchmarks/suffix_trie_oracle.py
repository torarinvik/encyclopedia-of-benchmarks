"""Oracle for the bounded pinned Python SuffixTree-as-suffix-trie search workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_PATTERN_LENGTH = 16
MAX_VALID_INPUT_VALUES = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MIN_ASCII_CODE = 0
MAX_ASCII_CODE = 127
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode_input(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH:
        return None
    if not 0 <= pattern_length <= MAX_PATTERN_LENGTH:
        return None
    if len(values) != 2 + text_length + pattern_length:
        return None

    text_codes = values[2 : 2 + text_length]
    pattern_codes = values[2 + text_length :]
    if any(not MIN_ASCII_CODE <= value <= MAX_ASCII_CODE for value in text_codes + pattern_codes):
        return None
    return bytes(text_codes), bytes(pattern_codes)


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return 1 if the pattern path exists, 0 if absent, or -1 if invalid."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT
    text, pattern = decoded
    return int(pattern in text)
