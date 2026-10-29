"""Independent set-based oracle for the bounded dominator-tree workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 63
MAX_EDGES = 2047
MAX_INPUT_LENGTH = 3 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_VERTICES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
UNREACHABLE = 255


def _dominator_bytes(values: Sequence[int]) -> list[int] | None:
    """Compute the output with independent Python sets, or None for malformed input."""
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return None
    vertex_count, root, edge_count = values[:3]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= root < vertex_count:
        return None
    if not 0 <= edge_count <= MAX_EDGES or len(values) != 3 + 2 * edge_count:
        return None

    successors = [set() for _ in range(vertex_count)]
    predecessors = [set() for _ in range(vertex_count)]
    for edge in range(edge_count):
        source, target = values[3 + 2 * edge:5 + 2 * edge]
        if not 0 <= source < vertex_count or not 0 <= target < vertex_count:
            return None
        successors[source].add(target)
        predecessors[target].add(source)

    reachable = {root}
    pending = [root]
    while pending:
        source = pending.pop()
        for target in successors[source] - reachable:
            reachable.add(target)
            pending.append(target)

    dominators = {
        vertex: ({root} if vertex == root else set(reachable))
        for vertex in reachable
    }
    while True:
        updated = {root: {root}}
        for vertex in reachable - {root}:
            incoming = predecessors[vertex] & reachable
            if not incoming:
                return None
            common = set(reachable)
            for source in incoming:
                common.intersection_update(dominators[source])
            updated[vertex] = common | {vertex}
        if updated == dominators:
            break
        dominators = updated

    output = [UNREACHABLE] * vertex_count
    output[root] = root
    for vertex in reachable - {root}:
        strict = dominators[vertex] - {vertex}
        # Strict dominators form a chain; the deepest one has the largest set.
        output[vertex] = max(strict, key=lambda candidate: len(dominators[candidate]))
    return output


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return the shared byte-output ABI result and encoded immediate dominators."""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_INPUT_LENGTH or input_length != len(values)):
        return INVALID_RESULT, b""
    result = _dominator_bytes(values)
    if result is None:
        return INVALID_RESULT, b""
    required = len(result)
    if output_is_null and required > 0:
        return OUTPUT_ERROR, b""
    if output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""
    return required, bytes(result)
