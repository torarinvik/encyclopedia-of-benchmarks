"""One-pass survivor-stack reference for a bounded one-dimensional collision trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 66
MAX_WORKSPACE_BYTES = 512
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, ...] | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if input_is_null or not isinstance(values, (tuple, list)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != n + 1:
        return None
    items = tuple(values[1:])
    if any(value == 0 or not -127 <= value <= 127 for value in items):
        return None
    return items


def survivors(items: Sequence[int]) -> list[int]:
    stack: list[int] = []
    for incoming in items:
        keep_incoming = True
        while keep_incoming and stack and stack[-1] > 0 and incoming < 0:
            preceding = stack[-1]
            if preceding < -incoming:
                stack.pop()
            elif preceding == -incoming:
                stack.pop()
                keep_incoming = False
            else:
                keep_incoming = False
        if keep_incoming:
            stack.append(incoming)
    return stack


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    items = _decode(values, input_is_null, input_length)
    if items is None:
        return -1, b""
    final = survivors(items)
    payload = bytes([len(final), *(value & 0xFF for value in final)])
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
