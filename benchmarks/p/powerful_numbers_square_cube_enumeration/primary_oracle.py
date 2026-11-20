"""Powerful-number sequence by squarefree-b square/cube enumeration."""

from __future__ import annotations

from collections.abc import Sequence

MIN_LIMIT = 1
MAX_LIMIT = 100
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_VALUES = 14
MAX_OUTPUT_BYTES = 120
WORKSPACE_BYTES = 512
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _squarefree(value: int) -> bool:
    divisor = 2
    while divisor <= value // divisor:
        if value % (divisor * divisor) == 0:
            return False
        divisor += 1
    return True


def _enumerate(limit: int) -> tuple[int, ...]:
    values: list[int] = []
    b = 1
    while b * b * b <= limit:
        if _squarefree(b):
            cube = b * b * b
            a = 1
            while a * a * cube <= limit:
                values.append(a * a * cube)
                a += 1
        b += 1
    values.sort()
    return tuple(values)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not MIN_LIMIT <= values[0] <= MAX_LIMIT:
        return None
    return values[0]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    limit = _parse(values, input_is_null, input_length)
    if limit is None:
        return INVALID_RESULT, b""
    sequence = _enumerate(limit)
    words = (len(sequence), *sequence)
    staged = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
