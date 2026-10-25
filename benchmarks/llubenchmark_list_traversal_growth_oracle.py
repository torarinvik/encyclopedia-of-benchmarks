"""Independent oracle for the bounded LLUBenchmark list traversal/growth profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LISTS = 4
MAX_INITIAL_LENGTH = 4
MAX_ITERATIONS = 16
MAX_NODES = 36
MAX_INPUT_LENGTH = 3
GROWTH_MILLI = 333


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        values is not None and not isinstance(values, (list, tuple))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
    ):
        return -1, b""
    if input_is_null or values is None or len(values) != 3:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""
    num_lists, initial_length, iterations = values
    if not 1 <= num_lists <= MAX_LISTS or not 1 <= initial_length <= MAX_INITIAL_LENGTH:
        return -1, b""
    if not 0 <= iterations <= MAX_ITERATIONS:
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16:
        return -2, b""

    # Fixed node-index links preserve the source's per-list topology while
    # keeping allocation bounded and identical across the target languages.
    next_node = [-1] * MAX_NODES
    node_count = [0] * MAX_NODES
    heads = [-1] * MAX_LISTS
    tails = [-1] * MAX_LISTS
    allocated = 0
    for _ in range(initial_length):
        for list_index in range(num_lists):
            node = allocated
            allocated += 1
            next_node[node] = heads[list_index]
            heads[list_index] = node
            if tails[list_index] == -1:
                tails[list_index] = node

    accumulate = 0
    growth_milli = 0
    for _ in range(iterations):
        for list_index in range(num_lists):
            node = heads[list_index]
            while node != -1:
                accumulate += node_count[node]
                node_count[node] += 1
                node = next_node[node]
        growth_milli += GROWTH_MILLI
        new_per_list = growth_milli // 1000
        growth_milli -= new_per_list * 1000
        for ordinal in range(new_per_list, 0, -1):
            for list_index in range(num_lists):
                node = allocated
                allocated += 1
                node_count[node] = list_index + ordinal
                next_node[node] = -1
                next_node[tails[list_index]] = node
                tails[list_index] = node

    payload = struct.pack("<qq", accumulate, allocated)
    return 2, payload
