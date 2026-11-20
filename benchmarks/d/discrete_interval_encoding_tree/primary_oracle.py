"""Mutable interval-BST reference for the bounded DIET operation trace."""

import struct

MAX_OPERATIONS = 32
MIN_KEY = -15
MAX_KEY = 15
MAX_VALID_INPUT_WORDS = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
WORKSPACE_BYTES = 8192


def _input(values, input_is_null, input_length):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    length = len(values)
    if not 1 <= length <= MAX_PARSEABLE_INPUT_WORDS:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != length):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or length != 1 + 2 * count:
        return None
    operations = []
    for index in range(count):
        opcode, key = values[1 + 2 * index:3 + 2 * index]
        if opcode not in (0, 1, 2) or not MIN_KEY <= key <= MAX_KEY:
            return None
        operations.append((opcode, key))
    return operations


def _run(operations):
    # Nodes are [lo, hi, left_index, right_index]; -1 is empty.
    nodes = []
    root = -1
    cardinality = 0
    interval_count = 0
    records = []

    def new_node(lo, hi, left=-1, right=-1):
        nodes.append([lo, hi, left, right])
        return len(nodes) - 1

    def pop_max(tree):
        node = nodes[tree]
        if node[3] == -1:
            return node[2], node[0], node[1]
        new_right, lo, hi = pop_max(node[3])
        node[3] = new_right
        return tree, lo, hi

    def pop_min(tree):
        node = nodes[tree]
        if node[2] == -1:
            return node[3], node[0], node[1]
        new_left, lo, hi = pop_min(node[2])
        node[2] = new_left
        return tree, lo, hi

    def maximum_interval(tree):
        while nodes[tree][3] != -1:
            tree = nodes[tree][3]
        return nodes[tree][0], nodes[tree][1]

    def minimum_interval(tree):
        while nodes[tree][2] != -1:
            tree = nodes[tree][2]
        return nodes[tree][0], nodes[tree][1]

    def contains(tree, key):
        while tree != -1:
            node = nodes[tree]
            if key < node[0]:
                tree = node[2]
            elif key > node[1]:
                tree = node[3]
            else:
                return True
        return False

    def insert(tree, key):
        nonlocal interval_count
        if tree == -1:
            interval_count += 1
            return new_node(key, key), True
        node = nodes[tree]
        if key < node[0]:
            if key + 1 == node[0]:
                node[0] = key
                if node[2] != -1:
                    pred_lo, pred_hi = maximum_interval(node[2])
                    if pred_hi + 1 == key:
                        new_left, pred_lo, pred_hi = pop_max(node[2])
                        node[0] = pred_lo
                        node[2] = new_left
                        interval_count -= 1
                return tree, True
            node[2], changed = insert(node[2], key)
            return tree, changed
        if key > node[1]:
            if key == node[1] + 1:
                node[1] = key
                if node[3] != -1:
                    succ_lo, succ_hi = minimum_interval(node[3])
                    if key + 1 == succ_lo:
                        new_right, succ_lo, succ_hi = pop_min(node[3])
                        node[1] = succ_hi
                        node[3] = new_right
                        interval_count -= 1
                return tree, True
            node[3], changed = insert(node[3], key)
            return tree, changed
        return tree, False

    def delete(tree, key):
        nonlocal interval_count
        if tree == -1:
            return -1, False
        node = nodes[tree]
        if key < node[0]:
            node[2], changed = delete(node[2], key)
            return tree, changed
        if key > node[1]:
            node[3], changed = delete(node[3], key)
            return tree, changed
        if node[0] == node[1]:
            interval_count -= 1
            if node[2] == -1:
                return node[3], True
            if node[3] == -1:
                return node[2], True
            new_left, pred_lo, pred_hi = pop_max(node[2])
            node[0], node[1], node[2] = pred_lo, pred_hi, new_left
            return tree, True
        if key == node[0]:
            node[0] += 1
            return tree, True
        if key == node[1]:
            node[1] -= 1
            return tree, True
        right_piece = new_node(key + 1, node[1], -1, node[3])
        node[1] = key - 1
        node[3] = right_piece
        interval_count += 1
        return tree, True

    for opcode, key in operations:
        if opcode == 0:
            root, changed = insert(root, key)
            if changed:
                cardinality += 1
        elif opcode == 1:
            root, changed = delete(root, key)
            if changed:
                cardinality -= 1
        present = 1 if contains(root, key) else 0
        records.append(64 * cardinality + 2 * interval_count + present)
    return b"".join(struct.pack("<q", record) for record in records)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    operations = _input(values, input_is_null, input_length)
    if operations is None:
        return -1, b""
    required = 8 * len(operations)
    if (output_is_null and required != 0) or (capacity is not None and capacity < required):
        return -2, b""
    return required, _run(operations)
