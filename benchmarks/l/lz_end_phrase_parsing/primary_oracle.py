"""Bounded direct-scan reference for greedy LZ-End phrase boundaries."""

MIN_TEXT_LENGTH = 0
MAX_TEXT_LENGTH = 64
ALPHABET_MIN = 0
ALPHABET_MAX = 255
MAX_VALID_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CHECKSUM = 133_120
PHRASE_MULTIPLIER = MAX_CHECKSUM + 1
MAX_RESULT = MAX_TEXT_LENGTH * PHRASE_MULTIPLIER + MAX_CHECKSUM


def parse(values):
    if values is None or not hasattr(values, "__len__"):
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
    if isinstance(n, bool) or not isinstance(n, int) or not MIN_TEXT_LENGTH <= n <= MAX_TEXT_LENGTH:
        return None
    if size != n + 1:
        return None
    try:
        text = list(values[1:])
    except (IndexError, KeyError, TypeError, ValueError, OverflowError):
        return None
    if any(isinstance(symbol, bool) or not isinstance(symbol, int) or not ALPHABET_MIN <= symbol <= ALPHABET_MAX
           for symbol in text):
        return None
    return text


def phrase_lengths(text):
    """Parse left-to-right; each copied prefix ends at a prior phrase boundary."""
    boundaries = []  # Exclusive text offsets after completed phrases.
    lengths = []
    position = 0
    n = len(text)
    while position < n:
        maximum_copy = n - position - 1  # Leave one trailing symbol in each phrase.
        best_copy = 0
        for copy_length in range(maximum_copy, 0, -1):
            candidate = text[position:position + copy_length]
            for boundary in reversed(boundaries):
                if boundary >= copy_length and text[boundary - copy_length:boundary] == candidate:
                    best_copy = copy_length
                    break
            if best_copy:
                break
        phrase_length = best_copy + 1
        lengths.append(phrase_length)
        position += phrase_length
        boundaries.append(position)
    return lengths


def checksum(lengths):
    return sum((index + 1) * phrase_length for index, phrase_length in enumerate(lengths))


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
    try:
        text = parse(values)
    except (IndexError, KeyError, TypeError, ValueError, OverflowError):
        return -1
    if text is None:
        return -1
    lengths = phrase_lengths(text)
    result = PHRASE_MULTIPLIER * len(lengths) + checksum(lengths)
    return result if result <= MAX_RESULT else -1


def expected(values):
    return expected_result(values)
