"""Bounded deterministic Forward–Backward–Trim SCC package oracle."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES
MAX_TASKS = 2 * MAX_NODES + 2


def _reach(mask: int, pivot: int, adjacency: list[int], reverse: bool) -> int:
    seen = 1 << pivot
    while True:
        expanded = seen
        for source in range(MAX_NODES):
            bit = 1 << source
            if not seen & bit or not mask & bit:
                continue
            for destination in range(MAX_NODES):
                other = 1 << destination
                has_edge = (adjacency[destination] & bit) if reverse else (adjacency[source] & other)
                if mask & other and has_edge:
                    expanded |= other
        if expanded == seen:
            return seen
        seen = expanded


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if len(values) < 2:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 2 * m:
        return -1, b""
    adjacency = [0] * MAX_NODES
    arcs = set()
    for index in range(2, len(values), 2):
        source, destination = values[index:index + 2]
        if not 0 <= source < n or not 0 <= destination < n:
            return -1, b""
        if (source, destination) in arcs:
            return -1, b""
        arcs.add((source, destination))
        adjacency[source] |= 1 << destination

    labels = [-1] * n
    tasks = [0] * MAX_TASKS
    task_count = 1
    tasks[0] = (1 << n) - 1
    while task_count:
        task_count -= 1
        active = tasks[task_count]
        while active:
            trimmed = 0
            for vertex in range(n):
                bit = 1 << vertex
                if not active & bit:
                    continue
                outgoing = adjacency[vertex] & active
                incoming = any(active & (1 << source) and adjacency[source] & bit
                               for source in range(n))
                if not outgoing or not incoming:
                    trimmed |= bit
            if not trimmed:
                break
            for vertex in range(n):
                if trimmed & (1 << vertex):
                    labels[vertex] = vertex
            active &= ~trimmed
        if not active:
            continue
        pivot = (active & -active).bit_length() - 1
        forward = _reach(active, pivot, adjacency, False)
        backward = _reach(active, pivot, adjacency, True)
        component = forward & backward
        representative = (component & -component).bit_length() - 1
        for vertex in range(n):
            if component & (1 << vertex):
                labels[vertex] = representative
        child_masks = (active & ~(forward | backward),
                       forward & ~backward, backward & ~forward)
        for child in child_masks:
            if child:
                if task_count >= MAX_TASKS:
                    return -1, b""
                tasks[task_count] = child
                task_count += 1

    output = b"".join(struct.pack("<q", value) for value in labels)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
