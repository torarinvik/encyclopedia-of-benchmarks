"""McCreight radix priority-search-tree reference for three-sided reporting."""

from __future__ import annotations

from collections.abc import Sequence

MIN_POINTS = 0
MAX_POINTS = 8
MAX_QUERIES = 7
X_DOMAIN = 32
MIN_Y = -64
MAX_Y = 63
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_POINTS + 3 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
# Shared scalar-suite metadata spelling.
MAX_VALID_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_RESULT = (1 << (8 * MAX_QUERIES)) - 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[tuple[int, int, int]],
                                               list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, q = values[0], values[1]
    if not MIN_POINTS <= n <= MAX_POINTS or not 0 <= q <= MAX_QUERIES:
        return None
    expected_length = 2 + 3 * n + 3 * q
    if len(values) != expected_length:
        return None
    points: list[tuple[int, int, int]] = []
    seen_x: set[int] = set()
    seen_labels: set[int] = set()
    at = 2
    for _ in range(n):
        x, y, label = values[at:at + 3]
        at += 3
        if (not 0 <= x < X_DOMAIN or not MIN_Y <= y <= MAX_Y
                or not 0 <= label < MAX_POINTS or x in seen_x
                or label in seen_labels):
            return None
        seen_x.add(x)
        seen_labels.add(label)
        points.append((x, y, label))
    queries: list[tuple[int, int, int]] = []
    for _ in range(q):
        x0, x1, y1 = values[at:at + 3]
        at += 3
        if (not 0 <= x0 <= x1 < X_DOMAIN or not MIN_Y <= y1 <= MAX_Y):
            return None
        queries.append((x0, x1, y1))
    return points, queries


def _insert(root: int, point: tuple[int, int, int],
            node_x: list[int], node_y: list[int], node_label: list[int],
            left: list[int], right: list[int], node_count: int) -> tuple[int, int]:
    """Insert using the paper's radix split and strict lower-y promotion."""
    pending_x, pending_y, pending_label = point
    if root < 0:
        node_x[node_count] = pending_x
        node_y[node_count] = pending_y
        node_label[node_count] = pending_label
        left[node_count] = right[node_count] = -1
        return node_count, node_count + 1
    current = root
    low, high = 0, X_DOMAIN
    while True:
        if pending_y < node_y[current]:
            pending_x, node_x[current] = node_x[current], pending_x
            pending_y, node_y[current] = node_y[current], pending_y
            pending_label, node_label[current] = node_label[current], pending_label
        middle = (low + high) // 2
        if pending_x < middle:
            child = left[current]
            if child < 0:
                child = node_count
                node_x[child], node_y[child], node_label[child] = (
                    pending_x, pending_y, pending_label)
                left[child] = right[child] = -1
                left[current] = child
                return root, node_count + 1
            current = child
            high = middle
        else:
            child = right[current]
            if child < 0:
                child = node_count
                node_x[child], node_y[child], node_label[child] = (
                    pending_x, pending_y, pending_label)
                left[child] = right[child] = -1
                right[current] = child
                return root, node_count + 1
            current = child
            low = middle


def _report(node: int, low: int, high: int, x0: int, x1: int, y1: int,
            node_x: list[int], node_y: list[int], node_label: list[int],
            left: list[int], right: list[int], mask: int) -> int:
    if node < 0 or x1 < low or x0 >= high or node_y[node] > y1:
        return mask
    if x0 <= node_x[node] <= x1:
        mask |= 1 << node_label[node]
    middle = (low + high) // 2
    mask = _report(left[node], low, middle, x0, x1, y1,
                   node_x, node_y, node_label, left, right, mask)
    return _report(right[node], middle, high, x0, x1, y1,
                   node_x, node_y, node_label, left, right, mask)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Pack each query's labeled hit mask into one consecutive result byte."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    points, queries = parsed
    node_x = [0] * MAX_POINTS
    node_y = [0] * MAX_POINTS
    node_label = [0] * MAX_POINTS
    left = [-1] * MAX_POINTS
    right = [-1] * MAX_POINTS
    root = -1
    node_count = 0
    for point in points:
        root, node_count = _insert(root, point, node_x, node_y, node_label,
                                   left, right, node_count)
    result = 0
    for query_index, (x0, x1, y1) in enumerate(queries):
        mask = _report(root, 0, X_DOMAIN, x0, x1, y1,
                       node_x, node_y, node_label, left, right, 0)
        result |= mask << (8 * query_index)
    return result
