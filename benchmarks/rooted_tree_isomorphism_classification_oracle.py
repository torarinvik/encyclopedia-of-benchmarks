"""Recursive nested-tuple oracle for rooted-tree isomorphism classes."""

from collections.abc import Sequence

MAX_TREES = 16
MAX_TREE_VERTICES = 32
MAX_TOTAL_VERTICES = 128
MAX_INPUT_LENGTH = 1 + 2 * MAX_TREES * MAX_TREE_VERTICES
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_TOTAL_VERTICES


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the status and one first-occurrence class byte per rooted tree."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (capacity is not None and (type(capacity) is not int or capacity < 0))
        or (
            input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
        )
    ):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (
        not isinstance(values, (tuple, list))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
        or (input_length is not None and input_length != len(values))
    ):
        return -1, b""
    if not values:
        return -1, b""
    tree_count = values[0]
    if not 1 <= tree_count <= MAX_TREES:
        return -1, b""

    position = 1
    total_vertices = 0
    root_signatures: list[tuple[object, ...]] = []
    for _ in range(tree_count):
        if position + 2 > len(values):
            return -1, b""
        n, root = values[position : position + 2]
        position += 2
        if not 1 <= n <= MAX_TREE_VERTICES or not 0 <= root < n:
            return -1, b""
        total_vertices += n
        if total_vertices > MAX_TOTAL_VERTICES:
            return -1, b""
        edge_count = n - 1
        if position + 2 * edge_count > len(values):
            return -1, b""

        adjacency: list[list[int]] = [[] for _ in range(n)]
        seen_edges: set[tuple[int, int]] = set()
        for _edge in range(edge_count):
            left, right = values[position : position + 2]
            position += 2
            if not (0 <= left < n and 0 <= right < n) or left == right:
                return -1, b""
            edge = (min(left, right), max(left, right))
            if edge in seen_edges:
                return -1, b""
            seen_edges.add(edge)
            adjacency[left].append(right)
            adjacency[right].append(left)

        visited: set[int] = set()

        def rooted_signature(vertex: int, parent: int) -> tuple[object, ...] | None:
            visited.add(vertex)
            children: list[tuple[object, ...]] = []
            for neighbor in adjacency[vertex]:
                if neighbor == parent:
                    continue
                if neighbor in visited:
                    return None
                child_signature = rooted_signature(neighbor, vertex)
                if child_signature is None:
                    return None
                children.append(child_signature)
            return tuple(sorted(children))

        signature = rooted_signature(root, -1)
        if signature is None or len(visited) != n:
            return -1, b""
        root_signatures.append(signature)

    if position != len(values):
        return -1, b""

    class_ids: dict[tuple[object, ...], int] = {}
    labels = bytearray()
    for signature in root_signatures:
        if signature not in class_ids:
            class_ids[signature] = len(class_ids)
        labels.append(class_ids[signature])
    output = bytes(labels)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
