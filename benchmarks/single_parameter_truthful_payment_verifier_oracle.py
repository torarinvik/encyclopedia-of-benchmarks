"""Independent unit-interval verifier for the bounded payment profile."""

from __future__ import annotations

from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > 18
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    bid, count = values[0], values[1]
    if not 0 <= bid <= 16 or not 1 <= count <= 8 or len(values) != 2 + 2 * count:
        return -1, b""
    points = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(count)]
    for i, (point, load) in enumerate(points):
        if not 0 <= point < 16 or not 0 <= load <= 16:
            return -1, b""
        if (i == 0 and point != 0) or (i > 0 and (point <= points[i - 1][0] or load > points[i - 1][1])):
            return -1, b""
    allocation = 0
    if bid < 16:
        for point, load in points:
            if point > bid:
                break
            allocation = load
    integral = sum(load for unit in range(bid, 16)
                   for i, (start, _) in enumerate(points)
                   if start <= unit < (points[i + 1][0] if i + 1 < count else 16)
                   for load in [points[i][1]])
    payment = bid * allocation + integral
    payload = allocation.to_bytes(8, "little", signed=True) + payment.to_bytes(8, "little", signed=True)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16:
        return -2, b""
    return 16, payload
