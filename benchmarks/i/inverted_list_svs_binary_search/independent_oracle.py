"""Direct set-membership reference for shortest-list-first intersection."""
from __future__ import annotations

import struct
from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def _parse(values: Sequence[int]):
    if not 3 <= len(values) <= 266:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    count = values[0]
    if not 2 <= count <= 8:
        return None
    at = 1
    lists: list[tuple[int, ...]] = []
    for _ in range(count):
        if at >= len(values):
            return None
        size = values[at]
        at += 1
        if not 0 <= size <= 32 or size > len(values) - at:
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
    shortest = min(lists, key=len)
    memberships = [set(items) for items in lists]
    result = [value for value in shortest
              if all(value in membership for membership in memberships)]
    required = min(map(len, lists)) * 4
    if output_is_null and required > 0 or capacity is not None and capacity < required:
        return -2, b""
    payload = b"".join(struct.pack("<i", value) for value in result)
    return len(result), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
