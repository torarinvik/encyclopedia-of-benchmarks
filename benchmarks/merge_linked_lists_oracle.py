"""Oracle for the bounded C linked-list splice operation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LIST_LENGTH = 32
MAX_TOTAL_NODES = 2 * MAX_LIST_LENGTH
MAX_VALID_INPUT_LENGTH = 2 + MAX_TOTAL_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_TOTAL_NODES
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the values reached from head1 after the pinned alternating splices."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None and type(input_length) is not int)):
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    first_length, second_length = values[:2]
    if (not 0 <= first_length <= MAX_LIST_LENGTH
            or not 0 <= second_length <= MAX_LIST_LENGTH
            or first_length + second_length > MAX_TOTAL_NODES
            or len(values) != 2 + first_length + second_length
            or any(value < I32_MIN or value > I32_MAX for value in values[2:])):
        return INVALID_RESULT, b""

    # Each packed list gets its own nodes, just as the C demo allocates distinct
    # node objects for head1 and head2. next indices model the source pointer links.
    nodes: list[list[int]] = []
    for index, value in enumerate(values[2:2 + first_length]):
        nodes.append([value, index + 1 if index + 1 < first_length else -1])
    second_start = first_length
    for index, value in enumerate(values[2 + first_length:]):
        nodes.append([value, second_start + index + 1
                      if index + 1 < second_length else -1])

    head1 = 0 if first_length else -1
    head2 = second_start if second_length else -1
    temp1, temp2 = head1, head2
    holder2 = -1
    while temp1 != -1 and temp2 != -1:
        holder1 = nodes[temp1][1]
        nodes[temp1][1] = temp2
        if holder1 != -1:
            holder2 = nodes[temp2][1]
            nodes[temp2][1] = holder1
        temp1 = holder1
        temp2 = holder2

    output_values: list[int] = []
    node = head1
    while node != -1:
        if not 0 <= node < len(nodes) or len(output_values) >= MAX_TOTAL_NODES:
            return INVALID_RESULT, b""
        output_values.append(nodes[node][0])
        node = nodes[node][1]
    encoded = b"".join(struct.pack("<q", value) for value in output_values)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR_RESULT, b""
    return len(encoded), encoded
