"""Independent oracle for the bounded Ruby UnweightedGraph trace benchmark."""

from __future__ import annotations

import struct

MAX_INITIAL_NODES = 12
MAX_OPERATIONS = 16
MAX_VALID_INPUT_LENGTH = 63
MAX_PARSEABLE_INPUT_LENGTH = 64
MAX_OUTPUT_BYTES = 648
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


class InvalidInput(ValueError):
    pass


def _i32(value: int) -> bool:
    return I32_MIN <= value <= I32_MAX


def run(values: list[int]) -> bytes:
    """Run a valid or invalid input trace and return its little-endian output."""
    if not isinstance(values, (list, tuple)):
        raise InvalidInput("input must be a list or tuple of signed 64-bit integers")
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("input length is outside the parseable range")
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        raise InvalidInput("input words must be signed 64-bit integers")
    directed, raw_node_count, raw_operation_count = values[:3]
    if directed not in (0, 1):
        raise InvalidInput("directed flag must be zero or one")
    if not 0 <= raw_node_count <= MAX_INITIAL_NODES:
        raise InvalidInput("initial node count is outside the supported range")
    if not 0 <= raw_operation_count <= MAX_OPERATIONS:
        raise InvalidInput("operation count is outside the supported range")
    node_count = raw_node_count
    operation_count = raw_operation_count
    expected_length = 3 + node_count + operation_count * 3
    if len(values) != expected_length:
        raise InvalidInput("input length does not match the declared trace")

    nodes: set[int] = set()
    neighbors: dict[int, list[int]] = {}
    for node in values[3 : 3 + node_count]:
        if not _i32(node) or node in nodes:
            raise InvalidInput("initial nodes must be unique signed 32-bit values")
        nodes.add(node)
        neighbors[node] = []

    output_words: list[int] = []
    offset = 3 + node_count
    for operation_index in range(operation_count):
        op, first, second = values[offset + 3 * operation_index : offset + 3 * operation_index + 3]
        if not _i32(first) or not _i32(second):
            raise InvalidInput("operation node values must be signed 32-bit integers")
        if op == 0:
            if second != 0 or first in nodes:
                raise InvalidInput("add_node requires a fresh node and a zero reserved field")
            nodes.add(first)
            neighbors[first] = []
        elif op == 1:
            if first not in nodes or (not directed and second not in nodes):
                raise InvalidInput("edge endpoint is outside the valid graph domain")
            if second in neighbors[first]:
                raise InvalidInput("duplicate edges are outside the valid trace domain")
            neighbors[first].append(second)
            if not directed and first not in neighbors[second]:
                neighbors[second].append(first)
        elif op == 2:
            if second != 0 or first not in nodes:
                raise InvalidInput("neighbors requires an existing node and a zero reserved field")
            adjacent = sorted(neighbors[first])
            output_words.extend((first, len(adjacent), *adjacent))
        else:
            raise InvalidInput("operation code must be zero, one, or two")

    output_bytes = b"".join(struct.pack("<q", word) for word in output_words)
    if len(output_bytes) > MAX_OUTPUT_BYTES:
        raise InvalidInput("output exceeds the bounded ABI")
    return output_bytes


def encode_i64(values: list[int]) -> bytes:
    return b"".join(struct.pack("<q", value) for value in values)
