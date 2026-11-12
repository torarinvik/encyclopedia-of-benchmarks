"""Independent bounded oracle for min Cartesian-tree parent arrays."""

from __future__ import annotations

import struct

MAX_N = 128
MAX_VALUE = 1_000_000_000
MAX_PARSEABLE_INPUT_LENGTH = 1 + MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null:
        return -1, b""
    try:
        data = tuple(values)
    except TypeError:
        return -1, b""
    length = len(data) if input_length is None else input_length
    if (not isinstance(length, int) or length < 1
            or length > MAX_PARSEABLE_INPUT_LENGTH or length != len(data)):
        return -1, b""
    n = data[0]
    if not isinstance(n, int) or not 1 <= n <= MAX_N or length != n + 1:
        return -1, b""
    keys = data[1:]
    if any(not isinstance(key, int) or not 0 <= key <= MAX_VALUE for key in keys):
        return -1, b""
    # Use recursive interval minima as an independent, quadratic reference.
    # Python's min chooses the first equal key, defining the local stable tie rule.
    parent = list(range(n))

    def build(left: int, right: int, parent_index: int | None) -> None:
        if left >= right:
            return
        root = min(range(left, right), key=keys.__getitem__)
        parent[root] = root if parent_index is None else parent_index
        build(left, root, root)
        build(root + 1, right, root)

    build(0, n, None)
    payload = b"".join(struct.pack("<q", item) for item in parent)
    if output_is_null or output_capacity is None or output_capacity < len(payload):
        return -2, b""
    return len(payload), payload


def validate_output(values, output: bytes) -> bool:
    """Check a parent-array certificate without rebuilding by a stack."""
    result, expected = expected_output(values, MAX_OUTPUT_BYTES)
    if result < 0 or len(output) != result:
        return False
    n = len(values) - 1
    parent = list(struct.unpack("<" + "q" * n, output))
    if any(not 0 <= p < n for p in parent):
        return False
    roots = [i for i, p in enumerate(parent) if i == p]
    if len(roots) != 1:
        return False
    left = [-1] * n
    right = [-1] * n
    for child, p in enumerate(parent):
        if child == p:
            continue
        if child < p:
            if left[p] != -1:
                return False
            left[p] = child
        else:
            if right[p] != -1:
                return False
            right[p] = child
        if values[p + 1] > values[child + 1]:
            return False
    seen = []
    stack = []
    node = roots[0]
    while stack or node != -1:
        while node != -1:
            stack.append(node)
            node = left[node]
        node = stack.pop()
        seen.append(node)
        node = right[node]
    return seen == list(range(n)) and output == expected
