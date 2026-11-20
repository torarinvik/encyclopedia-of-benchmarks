"""Direct heap-index-to-slot reference for static vEB layout search."""

import struct

MAX_HEIGHT = 4
MAX_QUERIES = 4
MAX_PARSEABLE_INPUT_WORDS = 2 + MAX_QUERIES + 1
MAX_OUTPUT_BYTES = 328
WORKSPACE_BYTES = 2048


def _parse(values, input_is_null, input_length):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
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


def _slot_for(heap_id, root_id, height, base):
    if heap_id == root_id:
        return base
    if height == 1:
        raise ValueError("heap node is outside its declared subtree")
    root_depth = root_id.bit_length() - 1
    node_depth = heap_id.bit_length() - 1
    top_height = height // 2
    if node_depth - root_depth < top_height:
        return _slot_for(heap_id, root_id, top_height, base)
    bottom_height = height - top_height
    cut_depth = root_depth + top_height
    cut_root = heap_id >> (node_depth - cut_depth)
    bottom_number = cut_root - (root_id << top_height)
    top_size = (1 << top_height) - 1
    bottom_size = (1 << bottom_height) - 1
    bottom_base = base + top_size + bottom_number * bottom_size
    return _slot_for(heap_id, cut_root, bottom_height, bottom_base)


def _inorder_keys(heap_id, height, low, result):
    if height == 0:
        return low
    low = _inorder_keys(2 * heap_id, height - 1, low, result)
    result[heap_id] = low
    low += 1
    return _inorder_keys(2 * heap_id + 1, height - 1, low, result)


def _result_words(height, queries, node_count):
    layout = [0] * node_count
    for heap_id in range(1, node_count + 1):
        layout[_slot_for(heap_id, 1, height, 0)] = heap_id
    key_by_heap = [0] * (node_count + 1)
    _inorder_keys(1, height, 0, key_by_heap)
    words = [node_count, *layout, len(queries)]
    for query in queries:
        heap_id = 1
        path = []
        found = -1
        while heap_id <= node_count:
            path.append(_slot_for(heap_id, 1, height, 0))
            node_key = key_by_heap[heap_id]
            if query == node_key:
                found = heap_id
                break
            heap_id = 2 * heap_id if query < node_key else 2 * heap_id + 1
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
    return required, b"".join(struct.pack("<q", word) for word in words)
