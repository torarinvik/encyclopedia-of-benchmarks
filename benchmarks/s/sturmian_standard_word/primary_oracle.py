"""Primary reference: build standard words by the directive recurrence."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "sturmian_standard_word"
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_STEPS = 4
MAX_REPEAT = 2
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_OUTPUT_BYTES = 41
WORKSPACE_BYTES = 512


def _decode(values: Sequence[int], input_is_null: bool,
            input_length: int) -> tuple[int, ...] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    steps = values[0]
    if not 0 <= steps <= MAX_STEPS or input_length != steps + 1:
        return None
    directives = tuple(values[1:])
    if steps and not 0 <= directives[0] <= MAX_REPEAT:
        return None
    if any(not 1 <= value <= MAX_REPEAT for value in directives[1:]):
        return None
    return directives


def _word(directives: tuple[int, ...]) -> bytes:
    previous = b"b"  # s[-1]
    current = b"a"   # s[0]
    for repeat in directives:
        following = current * repeat + previous
        previous, current = current, following
    return current


def expected_output(values: Sequence[int], capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT, b""
    directives = _decode(values, input_is_null, effective_length)
    if directives is None:
        return INVALID_RESULT, b""
    result = _word(directives)
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
