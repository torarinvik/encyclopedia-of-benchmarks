"""Independent Bellman-Ford oracle for bounded D'Esopo-Pape fixtures."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VERTICES = 16
MAX_EDGES = 64
MAX_WEIGHT = 1000
MAX_INPUT_LENGTH = 3 + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_VERTICES
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = [
    {
        "organization": "CP-Algorithms",
        "title": "D'Esopo-Pape algorithm",
        "url": "https://cp-algorithms.com/graph/desopo_pape.html",
        "role": "algorithm_navigation",
    },
    {
        "organization": "MIT OpenCourseWare",
        "title": "A Simple and Fast Label Correcting Algorithm for Shortest Paths",
        "url": "https://web.mit.edu/dimitrib/www/SLF.pdf",
        "role": "academic_label_correcting_description",
    },
]


def expected_output(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
    output_is_null: bool = False,
    output_capacity: int = MAX_OUTPUT_BYTES,
) -> tuple[int, bytes]:
    """Validate the packed graph, then compute distances with Bellman-Ford."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH
    ):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    vertex_count, edge_count, source = values[:3]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return INVALID_RESULT, b""
    if not 0 <= source < vertex_count or len(values) != 3 + 3 * edge_count:
        return INVALID_RESULT, b""
    edges: list[tuple[int, int, int]] = []
    for edge_index in range(edge_count):
        origin, destination, weight = values[3 + 3 * edge_index:6 + 3 * edge_index]
        if not 0 <= origin < vertex_count or not 0 <= destination < vertex_count:
            return INVALID_RESULT, b""
        if not 0 <= weight <= MAX_WEIGHT:
            return INVALID_RESULT, b""
        edges.append((origin, destination, weight))

    if type(output_capacity) is not int or output_capacity < 0:
        return OUTPUT_ERROR_RESULT, b""
    if output_is_null:
        return OUTPUT_ERROR_RESULT, b""
    byte_count = 8 * vertex_count
    if output_capacity < byte_count:
        return OUTPUT_ERROR_RESULT, b""

    distances: list[int | None] = [None] * vertex_count
    distances[source] = 0
    for _ in range(vertex_count - 1):
        changed = False
        for origin, destination, weight in edges:
            current = distances[origin]
            if current is None:
                continue
            candidate = current + weight
            if distances[destination] is None or candidate < distances[destination]:
                distances[destination] = candidate
                changed = True
        if not changed:
            break

    encoded = [distance if distance is not None else -1 for distance in distances]
    return byte_count, b"".join(struct.pack("<q", value) for value in encoded)

