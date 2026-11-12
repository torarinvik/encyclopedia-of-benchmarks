"""Quadratic nested-loop oracle for the deterministic hash-join byte contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS_PER_SIDE = 8
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_ROWS_PER_SIDE
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_ROWS_PER_SIDE * MAX_ROWS_PER_SIDE


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[list[int], list[int]] | None:
    if input_is_null or not isinstance(values, (tuple, list)) or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63) for item in values):
        return None
    left_count, right_count = values[0], values[1]
    if left_count < 0 or left_count > MAX_ROWS_PER_SIDE or right_count < 0 or right_count > MAX_ROWS_PER_SIDE:
        return None
    if 2 + left_count + right_count != len(values):
        return None
    cut = 2 + left_count
    return list(values[2:cut]), list(values[cut:])


def _enumerate(left: Sequence[int], right: Sequence[int]) -> bytes:
    encoded = bytearray()
    if len(left) < len(right):
        # Left is the build side, so the outer scan follows right-table order.
        for right_id, right_key in enumerate(right):
            for left_id, left_key in enumerate(left):
                if left_key == right_key:
                    encoded.append((left_id << 4) | right_id)
    else:
        # Equal sizes build right; the probe scan follows left-table order.
        for left_id, left_key in enumerate(left):
            for right_id, right_key in enumerate(right):
                if left_key == right_key:
                    encoded.append((left_id << 4) | right_id)
    return bytes(encoded)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    result = _enumerate(*parsed)
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
