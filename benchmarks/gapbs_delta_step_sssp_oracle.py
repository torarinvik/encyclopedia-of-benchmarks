"""Independent bounded shortest-path oracle for the GAPBS delta-step profile."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 4 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES
MAX_EDGE_WEIGHT = 32
INF_DISTANCE = 1_073_741_823
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _distances(values: Sequence[int] | None) -> list[int] | None:
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, edge_count, source, delta = values[:4]
    if not 1 <= n <= MAX_NODES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if not 0 <= source < n or not 1 <= delta <= 16:
        return None
    if len(values) != 4 + 3 * edge_count:
        return None
    edges: list[tuple[int, int, int]] = []
    for offset in range(4, len(values), 3):
        start, end, weight = values[offset : offset + 3]
        if not (0 <= start < n and 0 <= end < n and 0 <= weight <= MAX_EDGE_WEIGHT):
            return None
        edges.append((start, end, weight))

    # Independent Bellman-Ford oracle: the benchmark ports use distance buckets.
    distance = [INF_DISTANCE] * n
    distance[source] = 0
    for _ in range(n - 1):
        changed = False
        for start, end, weight in edges:
            if distance[start] != INF_DISTANCE:
                candidate = distance[start] + weight
                if candidate < distance[end]:
                    distance[end] = candidate
                    changed = True
        if not changed:
            break
    return distance


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI result and little-endian signed-64 distance vector."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    distance = _distances(values)
    if distance is None:
        return INVALID_RESULT, b""
    output = b"".join(struct.pack("<q", item) for item in distance)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    """Alias for verifiers that request a single reference function."""
    return expected_output(values)
