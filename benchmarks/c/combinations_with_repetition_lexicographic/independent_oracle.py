"""Recursive minimum-value-first reference for multiset combinations."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 4
MAX_R = 4
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_TUPLES = 35
MAX_OUTPUT_BYTES = 142
WORKSPACE_BYTES = 128
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _recursive_tuples(n: int, r: int) -> tuple[tuple[int, ...], ...]:
    output: list[tuple[int, ...]] = []
    prefix: list[int] = []

    def extend(minimum: int) -> None:
        if len(prefix) == r:
            output.append(tuple(prefix))
            return
        for value in range(minimum, n):
            prefix.append(value)
            extend(value)
            prefix.pop()

    if r == 0:
        output.append(())
    elif n != 0:
        extend(0)
    return tuple(output)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 2:
        return None
    n, r = values
    if not 0 <= n <= MAX_N or not 0 <= r <= MAX_R:
        return None
    return n, r


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
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    n, r = parsed
    tuples = _recursive_tuples(n, r)
    staged = len(tuples).to_bytes(2, "little") + bytes(
        value for combination in tuples for value in combination
    )
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
