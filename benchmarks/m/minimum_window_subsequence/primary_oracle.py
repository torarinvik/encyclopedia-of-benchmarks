"""Latest-start dynamic-programming oracle for minimum window subsequence."""

MAX_SEARCH_LENGTH = 128
MAX_PATTERN_LENGTH = 128
MAX_PARSEABLE_INPUT_LENGTH = MAX_SEARCH_LENGTH + MAX_PATTERN_LENGTH + 2
MAX_VALID_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_LENGTH = MAX_SEARCH_LENGTH
WORKSPACE_BYTES = MAX_PATTERN_LENGTH
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _parse(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return None
    search_length = values[0]
    if not 0 <= search_length <= MAX_SEARCH_LENGTH:
        return None
    pattern_length_index = 1 + search_length
    if pattern_length_index >= len(values):
        return None
    pattern_length = values[pattern_length_index]
    if not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return None
    if len(values) != search_length + pattern_length + 2:
        return None
    search = values[1:pattern_length_index]
    pattern = values[pattern_length_index + 1:]
    if any(not 0 <= byte <= 127 for byte in search + pattern):
        return None
    return search, pattern


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null):
        return INVALID_RESULT, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0
            or not isinstance(values, (list, tuple))
            or input_length != len(values)):
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    search, pattern = parsed
    latest_start = [-1] * len(pattern)
    best_start = -1
    best_length = len(search) + 1

    for end, byte in enumerate(search):
        for pattern_index in range(len(pattern) - 1, -1, -1):
            if byte != pattern[pattern_index]:
                continue
            candidate = end if pattern_index == 0 else latest_start[pattern_index - 1]
            if candidate >= 0 and candidate > latest_start[pattern_index]:
                latest_start[pattern_index] = candidate
        if byte == pattern[-1] and latest_start[-1] >= 0:
            start = latest_start[-1]
            length = end - start + 1
            if (length < best_length
                    or (length == best_length and (best_start < 0 or start < best_start))):
                best_start, best_length = start, length

    if best_start < 0:
        return 0, b""
    result = bytes(search[best_start:best_start + best_length])
    if output_is_null or (capacity is not None and capacity < len(result)):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(result), result
