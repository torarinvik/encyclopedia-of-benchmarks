"""Independent largest-remaining-item simulator for Next Fit Decreasing."""

from __future__ import annotations

from collections.abc import Sequence

CAPACITY = 1_000_000
MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 520


def _decode(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    count = values[0]
    if count < 0 or count > 64 or len(values) != count + 1:
        return None
    items = list(values[1:])
    return items if all(1 <= item <= CAPACITY for item in items) else None


def verify(values: Sequence[int] | None) -> tuple[int, bytes]:
    items = _decode(values)
    if items is None:
        return -1, b""
    remaining_items = [True] * len(items)
    order: list[int] = []
    for _ in range(len(items)):
        chosen = -1
        for index, size in enumerate(items):
            if remaining_items[index] and (chosen < 0 or size > items[chosen]):
                chosen = index
        order.append(chosen)
        remaining_items[chosen] = False

    assignment = [-1] * len(items)
    bins = 0
    open_load = 0
    for index in order:
        size = items[index]
        if bins == 0 or open_load + size > CAPACITY:
            assignment[index] = bins
            bins += 1
            open_load = size
        else:
            assignment[index] = bins - 1
            open_load += size
    words = [bins, *assignment]
    raw = b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = verify(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
