"""Independent all-boundary/all-length reference for LZ-End phrase parsing."""

from .primary_oracle import (
    ALPHABET_MAX,
    ALPHABET_MIN,
    MAX_CHECKSUM,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_TEXT_LENGTH,
    PHRASE_MULTIPLIER,
)


def _decode(values):
    if values is None:
        return None
    try:
        size = len(values)
    except (TypeError, ValueError, OverflowError):
        return None
    if size < 1 or size > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    try:
        n = values[0]
    except (IndexError, KeyError, TypeError, ValueError, OverflowError):
        return None
    if isinstance(n, bool) or not isinstance(n, int) or n < 0 or n > MAX_TEXT_LENGTH:
        return None
    if size != n + 1:
        return None
    try:
        text = list(values[1:])
    except (IndexError, KeyError, TypeError, ValueError, OverflowError):
        return None
    if any(isinstance(value, bool) or not isinstance(value, int) or value < ALPHABET_MIN or value > ALPHABET_MAX
           for value in text):
        return None
    return text


def _independent_lengths(text):
    boundaries = []
    lengths = []
    position = 0
    while position < len(text):
        remaining = len(text) - position
        best_copy = 0
        # Enumerate every legal source boundary and copy length, rather than
        # descending by length and stopping at the first hit.
        for boundary in boundaries:
            for copy_length in range(1, remaining):
                if boundary >= copy_length and all(
                    text[position + offset] == text[boundary - copy_length + offset]
                    for offset in range(copy_length)
                ):
                    if copy_length > best_copy:
                        best_copy = copy_length
        phrase_length = best_copy + 1
        lengths.append(phrase_length)
        position += phrase_length
        boundaries.append(position)
    return lengths


def expected_result(values, input_is_null=False, input_length=None):
    if not isinstance(input_is_null, bool):
        return -1
    if input_length is not None and (isinstance(input_length, bool) or not isinstance(input_length, int)):
        return -1
    if input_is_null or values is None:
        return -1
    try:
        actual_length = len(values)
    except (TypeError, ValueError, OverflowError):
        return -1
    length = actual_length if input_length is None else input_length
    if length < 0 or length > MAX_PARSEABLE_INPUT_LENGTH or length != actual_length:
        return -1
    text = _decode(values)
    if text is None:
        return -1
    lengths = _independent_lengths(text)
    check = sum(index * phrase_length for index, phrase_length in enumerate(lengths, 1))
    result = PHRASE_MULTIPLIER * len(lengths) + check
    return result if check <= MAX_CHECKSUM and result <= MAX_RESULT and sum(lengths) == len(text) else -1


def expected(values):
    return expected_result(values)
