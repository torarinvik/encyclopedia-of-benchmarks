"""Repeated local-rewrite reference; it does not maintain an arrival stack."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 66
MAX_WORKSPACE_BYTES = 512
MIN_SIZE = -127
MAX_SIZE = 127
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _read_frame(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> list[int] | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if input_is_null or not isinstance(values, (list, tuple)) or not values:
        return None
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    for value in values:
        if type(value) is not int or value < I64_MIN or value > I64_MAX:
            return None
    count = values[0]
    if count < 0 or count > MAX_N or len(values) != count + 1:
        return None
    sequence = list(values[1:])
    if any(value == 0 or value < MIN_SIZE or value > MAX_SIZE for value in sequence):
        return None
    return sequence


def reduce_pairs(sequence: list[int]) -> list[int]:
    current = list(sequence)
    while True:
        collision_at = None
        for index in range(len(current) - 1):
            if current[index] > 0 and current[index + 1] < 0:
                collision_at = index
                break
        if collision_at is None:
            return current

        index = collision_at
        left = current[index]
        right = current[index + 1]
        left_size = left
        right_size = -right
        if left_size > right_size:
            del current[index + 1]
        elif left_size < right_size:
            del current[index]
        else:
            del current[index:index + 2]


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    sequence = _read_frame(values, input_is_null, input_length)
    if sequence is None:
        return -1, b""
    final = reduce_pairs(sequence)
    payload = bytes([len(final), *(value & 0xFF for value in final)])
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
