"""Independent oracle for the bounded VersaBench R-tree root contraction."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 5
MAX_INPUT_LENGTH = 11
MAX_PARSEABLE_INPUT_LENGTH = 12
MAX_OUTPUT_ELEMENTS = 3
MAX_OUTPUT_BYTES = 24


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    if len(values) < 3:
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_NODES or len(values) != 1 + 2*n:
        return -1, b""
    nodes = [(values[1+2*i], values[2+2*i]) for i in range(n)]
    for i, (level, entries) in enumerate(nodes):
        if not 0 <= level <= 4 or not 0 <= entries <= 4:
            return -1, b""
        if i + 1 < n:
            if level == 0 or entries != 1 or nodes[i+1][0] != level - 1:
                return -1, b""
    last_level, last_count = nodes[-1]
    if last_level > 0 and last_count == 1:
        return -1, b""
    if last_level > 0 and last_count == 0 and n != 1:
        return -1, b""

    root = 0
    promotions = 0
    while nodes[root][0] > 0 and nodes[root][1] == 1:
        root += 1
        promotions += 1
    final_level, final_count = nodes[root]
    # delete() converts an empty internal root to an empty leaf root.
    if final_level > 0 and final_count == 0:
        final_level, final_count = 0, 0
    output = b"".join(struct.pack("<q", x) for x in (promotions, final_level, final_count))
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output


oracle = expected_output
