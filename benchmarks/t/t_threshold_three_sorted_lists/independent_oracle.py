"""Direct membership-count reference for a three-list 2-threshold query."""
from __future__ import annotations

import struct
from collections.abc import Sequence

I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def _parse(values: Sequence[int]):
    if len(values) < 6 or len(values) > 100:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    lists = []
    at = 0
    for _ in range(3):
        if at >= len(values):
            return None
        size = values[at]
        at += 1
        if not 1 <= size <= 32 or at + size > len(values):
            return None
        items = tuple(values[at:at + size])
        if (any(item < I32_MIN or item > I32_MAX for item in items)
                or any(items[index - 1] >= items[index] for index in range(1, size))):
            return None
        lists.append(items)
        at += size
    if at != len(values):
        return None
    return lists


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    lists = _parse(values)
    if lists is None:
        return -1, b""
    matches = sorted({value for items in lists for value in items
                      if sum(value in other for other in lists) >= 2})
    payload = b"".join(struct.pack("<q", word)
                       for word in [len(matches), *matches])
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
