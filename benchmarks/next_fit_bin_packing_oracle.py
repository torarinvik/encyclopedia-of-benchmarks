"""Primary online Next Fit bin-packing oracle for DOI 49."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ITEMS = 64
CAPACITY = 1_000_000
MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 520


def _parse(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_ITEMS or len(values) != count + 1:
        return None
    items = list(values[1:])
    if any(not 1 <= size <= CAPACITY for size in items):
        return None
    return items


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    items = _parse(values)
    if items is None:
        return -1, b""
    assignments: list[int] = []
    bins = 0
    remaining = 0
    for size in items:
        if bins == 0 or size > remaining:
            assignments.append(bins)
            bins += 1
            remaining = CAPACITY - size
        else:
            assignments.append(bins - 1)
            remaining -= size
    words = [bins, *assignments]
    raw = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
