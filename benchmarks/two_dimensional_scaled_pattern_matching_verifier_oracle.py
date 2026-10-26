"""Independent exact verifier using center-in-square coordinate arithmetic."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 186


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 6 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    height, width, pat_h, pat_w, scale_num, scale_den = values[:6]
    if not (1 <= height <= 12 and 1 <= width <= 12 and 1 <= pat_h <= 6 and 1 <= pat_w <= 6
            and 1 <= scale_den <= 8 and scale_den <= scale_num <= 2 * scale_den):
        return -1, b""
    if len(values) != 6 + height * width + pat_h * pat_w:
        return -1, b""
    alphabet = values[6:]
    if any(symbol < 0 or symbol > 255 for symbol in alphabet):
        return -1, b""
    pattern_start = height * width

    result: list[int] = [0]
    for origin_y in range(height):
        if scale_num * pat_h > scale_den * (height - origin_y):
            continue
        for origin_x in range(width):
            if scale_num * pat_w > scale_den * (width - origin_x):
                continue
            ok = True
            text_y = 0
            while text_y < height - origin_y:
                # A text pixel center is at text_y + 1/2. Exclude the far edge.
                center_y_twice = 2 * text_y + 1
                if center_y_twice * scale_den < 2 * scale_num * pat_h:
                    pattern_y = (center_y_twice * scale_den) // (2 * scale_num)
                    text_x = 0
                    while text_x < width - origin_x:
                        center_x_twice = 2 * text_x + 1
                        if center_x_twice * scale_den < 2 * scale_num * pat_w:
                            pattern_x = (center_x_twice * scale_den) // (2 * scale_num)
                            observed = alphabet[(origin_y + text_y) * width + origin_x + text_x]
                            wanted = alphabet[pattern_start + pattern_y * pat_w + pattern_x]
                            if observed != wanted:
                                ok = False
                                break
                        text_x += 1
                if not ok:
                    break
                text_y += 1
            if ok:
                result.extend((origin_y, origin_x))
                result[0] += 1
    payload = b"".join(struct.pack("<q", field) for field in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
