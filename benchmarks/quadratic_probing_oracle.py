"""Oracle for the bounded, pinned quadratic-probing insertion trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_CAPACITY = 5
MAX_CAPACITY = 31
MAX_INSERTS = 3
MAX_INPUT_LENGTH = 2 + MAX_INSERTS
MAX_OUTPUT_BYTES = 8 * (MAX_CAPACITY + 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None) -> tuple[int, list[int]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    capacity, insert_count = values[:2]
    if not MIN_CAPACITY <= capacity <= MAX_CAPACITY:
        return None
    if not 0 <= insert_count <= MAX_INSERTS or len(values) != 2 + insert_count:
        return None
    keys = list(values[2:])
    if any(not 0 <= key <= I64_MAX for key in keys):
        return None
    return capacity, keys


def _insert(table: list[int | None], data: int) -> bool:
    """Apply the pinned base class and quadratic collision method once.

    The boolean is false only when a probe route cycles before finding an
    empty slot. Such traces are outside this benchmark's terminating domain.
    With at most three insertions and capacity at least five, every valid
    bounded trace terminates without invoking the source's rehash path.
    """
    capacity = len(table)
    home = data % capacity
    if table[home] is None:
        table[home] = data
        return True
    if table[home] == data:
        return True

    probe = 1
    visited: set[int] = set()
    while True:
        slot = (home + probe * probe) % capacity
        # The source compares against `home`, not `data`; preserve that detail.
        if table[slot] is None or table[slot] == home:
            table[slot] = data
            return True
        if slot in visited:
            return False
        visited.add(slot)
        # balanced_factor is unchanged by probing. Under this workload's
        # capacity/count bounds it is always below the pinned 0.75 threshold.
        probe += 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the final table layout as little-endian i64 words."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    capacity, keys = parsed
    table: list[int | None] = [None] * capacity
    for key in keys:
        if not _insert(table, key):
            return INVALID_RESULT, b""

    words = [capacity, *(-1 if value is None else value for value in table)]
    output = b"".join(struct.pack("<q", word) for word in words)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
