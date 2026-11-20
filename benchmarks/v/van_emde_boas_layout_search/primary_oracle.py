"""Recursive top-tree/bottom-tree reference for static vEB layout search."""

import struct

MAX_HEIGHT = 4
MAX_NODES = (1 << MAX_HEIGHT) - 1
MAX_QUERIES = 4
MAX_VALID_INPUT_WORDS = 2 + MAX_QUERIES
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 328
WORKSPACE_BYTES = 2048


class _Node:
    __slots__ = ("heap_id", "key", "left", "right")

    def __init__(self, heap_id, key):
        self.heap_id = heap_id
        self.key = key
        self.left = None
        self.right = None


def _parse(values, input_is_null, input_length):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if len(values) < 2:
        return None
    height, query_count = values[:2]
    if not 1 <= height <= MAX_HEIGHT or not 0 <= query_count <= MAX_QUERIES:
        return None
    if len(values) != 2 + query_count:
        return None
    node_count = (1 << height) - 1
    queries = values[2:]
    if any(key < -1 or key > node_count for key in queries):
        return None
    return height, queries, node_count


def _make_tree(height):
    node_count = (1 << height) - 1

    def build(heap_id, low, high):
        if low > high:
            return None
        middle = (low + high) // 2
        node = _Node(heap_id, middle)
        node.left = build(2 * heap_id, low, middle - 1)
        node.right = build(2 * heap_id + 1, middle + 1, high)
        return node

    return build(1, 0, node_count - 1)


def _layout(root, height):
    if height == 1:
        return [root.heap_id]
    top_height = height // 2
    bottom_height = height - top_height
    order = _layout(root, top_height)
    bottom_roots = []

    def collect_level(node, remaining):
        if remaining == 0:
            bottom_roots.append(node)
            return
        collect_level(node.left, remaining - 1)
        collect_level(node.right, remaining - 1)

    collect_level(root, top_height)
    for bottom_root in bottom_roots:
        order.extend(_layout(bottom_root, bottom_height))
    return order


def _result_words(height, queries, node_count):
    root = _make_tree(height)
    order = _layout(root, height)
    slot_by_heap = {heap_id: slot for slot, heap_id in enumerate(order)}
    words = [node_count, *order, len(queries)]
    for query in queries:
        node = root
        path = []
        found = -1
        while node is not None:
            path.append(slot_by_heap[node.heap_id])
            if query == node.key:
                found = node.heap_id
                break
            node = node.left if query < node.key else node.right
        words.extend((len(path), *path, found))
    return words


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    words = _result_words(*parsed)
    required = 8 * len(words)
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    output = b"".join(struct.pack("<q", word) for word in words)
    return required, output
