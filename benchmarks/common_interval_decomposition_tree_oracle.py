"""Independent bounded oracle and certificate checker for strong interval trees."""

from __future__ import annotations

import struct

MAX_N = 48
MAX_PARSEABLE_INPUT_LENGTH = 1 + MAX_N
MAX_OUTPUT_BYTES = 8 * (1 + 4 * (2 * MAX_N - 1))


def _valid_input(values, input_length=None):
    try:
        data = tuple(values)
    except TypeError:
        return None
    length = len(data) if input_length is None else input_length
    if (not isinstance(length, int) or length < 2
            or length > MAX_PARSEABLE_INPUT_LENGTH or length != len(data)):
        return None
    n = data[0]
    if not isinstance(n, int) or not 1 <= n <= MAX_N or length != n + 1:
        return None
    permutation = data[1:]
    if any(not isinstance(value, int) or not 0 <= value < n
           for value in permutation):
        return None
    if len(set(permutation)) != n:
        return None
    return n, permutation


def _connected(permutation, left, right):
    """Use explicit sets rather than the ports' incremental min/max test."""
    values = set(permutation[left:right + 1])
    return (len(values) == right - left + 1
            and values == set(range(min(values), max(values) + 1)))


def _strong_tree(n, permutation):
    connected = []
    for left in range(n):
        for right in range(left, n):
            if _connected(permutation, left, right):
                connected.append((left, right))

    strong = []
    for interval in connected:
        left, right = interval
        overlaps = False
        for other_left, other_right in connected:
            if (left < other_left <= right < other_right
                    or other_left < left <= other_right < right):
                overlaps = True
                break
        if not overlaps:
            strong.append(interval)

    nodes = sorted(strong, key=lambda item: (-(item[1] - item[0] + 1), item[0]))
    parents = []
    for index, (left, right) in enumerate(nodes):
        containers = [
            (outer_right - outer_left + 1, parent_index)
            for parent_index, (outer_left, outer_right) in enumerate(nodes)
            if (outer_left <= left and right <= outer_right
                and (outer_left, outer_right) != (left, right))
        ]
        parents.append(min(containers)[1] if containers else -1)

    types = []
    for index, (left, right) in enumerate(nodes):
        children = sorted(
            (nodes[child] for child, parent in enumerate(parents) if parent == index),
            key=lambda item: item[0],
        )
        linear = True
        for first in range(len(children)):
            for last in range(first, len(children)):
                if not _connected(permutation, children[first][0], children[last][1]):
                    linear = False
                    break
            if not linear:
                break
        types.append(0 if linear else 1)

    return nodes, parents, types


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null:
        return -1, b""
    parsed = _valid_input(values, input_length)
    if parsed is None:
        return -1, b""
    n, permutation = parsed
    nodes, parents, types = _strong_tree(n, permutation)
    words = [len(nodes)]
    for (left, right), parent, node_type in zip(nodes, parents, types):
        words.extend((parent, left, right, node_type))
    payload = b"".join(struct.pack("<q", word) for word in words)
    effective_capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if output_is_null or effective_capacity < len(payload):
        return -2, b""
    return len(payload), payload


def validate_output(values, output: bytes) -> bool:
    """Validate tree certificates without requiring the canonical node order."""
    parsed = _valid_input(values)
    if parsed is None or len(output) % 8 != 0:
        return False
    n, permutation = parsed
    words = list(struct.unpack("<" + "q" * (len(output) // 8), output))
    if not words:
        return False
    count = words[0]
    if count < 1 or count > 2 * n - 1 or len(words) != 1 + 4 * count:
        return False

    records = [tuple(words[1 + 4 * i:5 + 4 * i]) for i in range(count)]
    intervals = [(record[1], record[2]) for record in records]
    if len(set(intervals)) != count:
        return False
    connected = [
        (left, right, frozenset(range(left, right + 1)))
        for left in range(n)
        for right in range(left, n)
        if _connected(permutation, left, right)
    ]
    expected_strong = set()
    for left, right, candidate_positions in connected:
        is_strong = True
        for _, _, other_positions in connected:
            if (not candidate_positions.isdisjoint(other_positions)
                    and not (candidate_positions.issubset(other_positions)
                             or other_positions.issubset(candidate_positions))):
                is_strong = False
                break
        if is_strong:
            expected_strong.add((left, right))
    if set(intervals) != expected_strong:
        return False

    roots = []
    for index, (parent, left, right, node_type) in enumerate(records):
        if not (0 <= left <= right < n) or node_type not in (0, 1):
            return False
        if parent == -1:
            roots.append(index)
        elif not (0 <= parent < index):
            return False
        elif not (records[parent][1] <= left and right <= records[parent][2]
                  and (records[parent][1], records[parent][2]) != (left, right)):
            return False
    if len(roots) != 1:
        return False
    root = records[roots[0]]
    if (root[1], root[2]) != (0, n - 1):
        return False

    for index, (_, left, right, node_type) in enumerate(records):
        children = sorted(
            ((record[1], record[2]) for record in records
             if record[0] == index),
            key=lambda item: item[0],
        )
        if children:
            if children[0][0] != left or children[-1][1] != right:
                return False
            if any(children[i][1] + 1 != children[i + 1][0]
                   for i in range(len(children) - 1)):
                return False
        linear = all(
            _connected(permutation, children[first][0], children[last][1])
            for first in range(len(children))
            for last in range(first, len(children))
        )
        if node_type != (0 if linear else 1):
            return False

        if index != roots[0]:
            parent = records[index][0]
            parent_left, parent_right = records[parent][1:3]
            if any(
                other != parent and other != index
                and parent_left <= records[other][1]
                and records[other][2] <= parent_right
                and records[other][1] <= left and right <= records[other][2]
                for other in range(count)
            ):
                return False
    return True
