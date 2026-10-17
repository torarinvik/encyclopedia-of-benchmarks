"""Independent bounded oracle for bijective pattern-to-substring matching."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PATTERN_LENGTH = 8
MAX_TEXT_LENGTH = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_PATTERN_LENGTH + MAX_TEXT_LENGTH
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _partition_matches(pattern: Sequence[int], text: Sequence[int]) -> bool:
    """Try every nonempty text partition and compare symbol equivalence classes."""
    pattern_length = len(pattern)
    text_length = len(text)
    if pattern_length == 0:
        return text_length == 0
    if pattern_length > text_length:
        return False

    chunks: list[tuple[int, ...]] = []

    def inspect_partition() -> bool:
        for left in range(pattern_length):
            for right in range(left + 1, pattern_length):
                if ((pattern[left] == pattern[right])
                        != (chunks[left] == chunks[right])):
                    return False
        return True

    def choose_chunk(pattern_index: int, text_index: int) -> bool:
        if pattern_index == pattern_length - 1:
            chunks.append(tuple(text[text_index:]))
            matched = inspect_partition()
            chunks.pop()
            return matched

        remaining_chunks = pattern_length - pattern_index - 1
        last_end = text_length - remaining_chunks
        for end in range(text_index + 1, last_end + 1):
            chunks.append(tuple(text[text_index:end]))
            if choose_chunk(pattern_index + 1, end):
                chunks.pop()
                return True
            chunks.pop()
        return False

    return choose_chunk(0, 0)


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    if (type(input_is_null) is not bool
            or (input_length is not None and type(input_length) is not int)):
        return INVALID_RESULT
    if input_is_null:
        if (values is not None and values != [] and values != ()):
            return INVALID_RESULT
        if input_length is None or not 1 <= input_length <= MAX_INPUT_LENGTH:
            return INVALID_RESULT
        return INVALID_RESULT
    if values is None:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple))
            or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT

    pattern_length, text_length = values[:2]
    if (not 0 <= pattern_length <= MAX_PATTERN_LENGTH
            or not 0 <= text_length <= MAX_TEXT_LENGTH
            or len(values) != 2 + pattern_length + text_length):
        return INVALID_RESULT

    pattern = values[2:2 + pattern_length]
    text = values[2 + pattern_length:]
    if any(not 0 <= value <= 127 for value in (*pattern, *text)):
        return INVALID_RESULT
    return int(_partition_matches(pattern, text))
