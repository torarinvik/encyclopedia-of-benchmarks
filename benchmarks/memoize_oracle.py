"""Oracle for bounded calls through the pinned JavaScript memoize wrapper."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_ARITY = 0
MAX_ARITY = 4
MAX_CALLS = 64
MIN_ARGUMENT = -100
MAX_ARGUMENT = 100
MAX_VALID_INPUT_LENGTH = 2 + MAX_ARITY * MAX_CALLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_CALLS + 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ENCODING_BASE = MAX_ARGUMENT - MIN_ARGUMENT + 1


def _decode_input(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None

    arity, call_count = values[:2]
    if not MIN_ARITY <= arity <= MAX_ARITY or not 0 <= call_count <= MAX_CALLS:
        return None
    if len(values) != 2 + arity * call_count:
        return None
    arguments = values[2:]
    if any(not MIN_ARGUMENT <= value <= MAX_ARGUMENT for value in arguments):
        return None
    return arity, call_count, arguments


def _callback_result(arguments: Sequence[int]) -> int:
    """Encode a fixed-arity tuple injectively as a small nonnegative integer."""
    result = 0
    for argument in arguments:
        result = result * ENCODING_BASE + (argument - MIN_ARGUMENT)
    return result


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return encoded memoized results and callback-call count, or ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, b""
    arity, call_count, flat_arguments = decoded

    cache: dict[tuple[int, ...], int] = {}
    results: list[int] = []
    callback_calls = 0
    for call_index in range(call_count):
        start = call_index * arity
        arguments = tuple(flat_arguments[start:start + arity])
        if arguments in cache:
            result = cache[arguments]
        else:
            result = _callback_result(arguments)
            cache[arguments] = result
            callback_calls += 1
        results.append(result)
    results.append(callback_calls)

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", value) for value in results)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
