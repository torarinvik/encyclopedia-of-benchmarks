"""Independent traversal oracle for bounded GAPBS Shiloach-Vishkin components."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_NODES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _labels(values: Sequence[int] | None) -> list[int] | None:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, edge_count = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    adjacency = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset : offset + 2]
        if not 0 <= u < v < n or (u, v) in seen:
            return None
        seen.add((u, v))
        adjacency[u].append(v)
        adjacency[v].append(u)
    for neighbors in adjacency:
        neighbors.sort()

    labels = [-1] * n
    for root in range(n):
        if labels[root] != -1:
            continue
        labels[root] = root
        stack = [root]
        while stack:
            node = stack.pop()
            for neighbor in adjacency[node]:
                if labels[neighbor] == -1:
                    labels[neighbor] = root
                    stack.append(neighbor)
    return labels


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return little-endian minimum-root labels or the ABI error status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    labels = _labels(values)
    if labels is None:
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", label) for label in labels)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    """Alias used by byte-output verifiers."""
    return expected_output(values)
