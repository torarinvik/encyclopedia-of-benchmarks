"""Independent set-membership-loop verifier for greedy min-sum set cover."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 12
MAX_M = 16
MAX_INPUT = 18


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values):
        return -1, b""
    n, set_count = values[0], values[1]
    masks = values[2:]
    if (not 1 <= n <= MAX_N or not 1 <= set_count <= MAX_M
            or len(masks) != set_count or any(mask <= 0 or mask >= (1 << n) for mask in masks)):
        return -1, b""

    members = [[bool(mask & (1 << element)) for element in range(n)] for mask in masks]
    hit = [False] * set_count
    selected: list[int] = []
    cover_sum = 0
    for slot in range(1, n + 1):
        pick = 0
        maximum = -1
        for element in range(n):
            if element in selected:
                continue
            new_hits = 0
            for set_id in range(set_count):
                if not hit[set_id] and members[set_id][element]:
                    new_hits += 1
            if new_hits > maximum:
                pick, maximum = element, new_hits
        selected.append(pick)
        for set_id in range(set_count):
            if not hit[set_id] and members[set_id][pick]:
                hit[set_id] = True
                cover_sum += slot
    result_values = [cover_sum, *selected]
    output = b"".join(struct.pack("<q", item) for item in result_values)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
