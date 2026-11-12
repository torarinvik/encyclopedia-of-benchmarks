"""Brute-force oracle for the bounded two-ended palindrome trace."""

import struct

MAX_QUERIES = 32
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_QUERIES
MAX_OUTPUT_BYTES = 24 * MAX_QUERIES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _summary(text):
    palindromes = set()
    for start in range(len(text)):
        for end in range(start + 1, len(text) + 1):
            candidate = tuple(text[start:end])
            if candidate == candidate[::-1]:
                palindromes.add(candidate)

    prefix = 0
    for length in range(1, len(text) + 1):
        candidate = text[:length]
        if candidate == candidate[::-1]:
            prefix = length
    suffix = 0
    for length in range(1, len(text) + 1):
        candidate = text[len(text) - length:]
        if candidate == candidate[::-1]:
            suffix = length
    return len(palindromes), prefix, suffix


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[Q, (operation, letter)*]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""

    queries = values[0]
    if not 1 <= queries <= MAX_QUERIES or len(values) != 1 + 2 * queries:
        return INVALID_RESULT, b""

    operations = []
    size = 0
    for query in range(queries):
        operation, letter = values[1 + 2 * query:3 + 2 * query]
        if operation in (0, 1):
            if not 0 <= letter < 26:
                return INVALID_RESULT, b""
            size += 1
        elif operation in (2, 3):
            if letter != 0 or size == 0:
                return INVALID_RESULT, b""
            size -= 1
        else:
            return INVALID_RESULT, b""
        operations.append((operation, letter))

    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(effective_capacity) is not int or effective_capacity < 0:
        return OUTPUT_ERROR, b""
    if output_is_null or effective_capacity < 24 * queries:
        return OUTPUT_ERROR, b""

    text = []
    output = bytearray()
    for operation, letter in operations:
        if operation == 0:
            text.insert(0, letter)
        elif operation == 1:
            text.append(letter)
        elif operation == 2:
            del text[0]
        else:
            text.pop()
        output.extend(struct.pack("<qqq", *_summary(text)))
    return len(output), bytes(output)
