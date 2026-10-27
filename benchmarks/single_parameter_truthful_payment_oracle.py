"""Primary exact-area oracle for the bounded Archer–Tardos payment profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_BID = 16
MAX_STEPS = 8
MAX_INPUT = 18


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    bid, count = values[:2]
    if not 0 <= bid <= MAX_BID or not 1 <= count <= MAX_STEPS or len(values) != 2 + 2 * count:
        return None
    points = []
    for i in range(count):
        point, load = values[2 + 2 * i:4 + 2 * i]
        if not 0 <= point < MAX_BID or not 0 <= load <= MAX_BID:
            return None
        if i == 0 and point != 0 or i > 0 and point <= points[-1][0]:
            return None
        if i > 0 and load > points[-1][1]:
            return None
        points.append((point, load))
    return bid, points


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    bid, points = parsed
    index = 0
    while index + 1 < len(points) and points[index + 1][0] <= bid:
        index += 1
    allocation = points[index][1] if bid < MAX_BID else 0
    area = 0
    for i, (start, load) in enumerate(points):
        end = points[i + 1][0] if i + 1 < len(points) else MAX_BID
        area += max(0, end - max(start, bid)) * load
    payment = bid * allocation + area
    payload = allocation.to_bytes(8, "little", signed=True) + payment.to_bytes(8, "little", signed=True)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16:
        return -2, b""
    return 16, payload
