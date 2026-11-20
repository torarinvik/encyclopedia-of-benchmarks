"""Path-copying leftist-heap reference for the bounded version workload."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_OPERATIONS = 64
MAX_KEY = 10_000
MAX_HEAP_SIZE = 128
MAX_NODES = 1024
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
EMPTY_RANK = 20_001
MAX_RESULT = 41_945_169_919
WORKSPACE_BYTES = 65_536


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values:
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None

    operations = []
    cursor = 1
    for operation_index in range(operation_count):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        cursor += 1
        width = 2 if kind in (0, 1) else 1 if kind in (2, 3) else 0
        if not width or cursor + width > len(values):
            return None
        args = values[cursor:cursor + width]
        cursor += width
        if kind == 0:
            base, key = args
            if not 0 <= base <= operation_index or not -MAX_KEY <= key <= MAX_KEY:
                return None
        elif kind == 1:
            left, right = args
            if not (0 <= left <= operation_index and 0 <= right <= operation_index):
                return None
        elif not 0 <= args[0] <= operation_index:
            return None
        operations.append((kind, *args))
    if cursor != len(values):
        return None
    return operations


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _decode(values, input_is_null, input_length)
    if operations is None:
        return -1

    # Node tuple is (key, left, right, null_path_length, subtree_size).
    nodes = [(0, 0, 0, 0, 0)]

    def allocate(node) -> int | None:
        if len(nodes) >= MAX_NODES:
            return None
        nodes.append(node)
        return len(nodes) - 1

    def meld(first: int, second: int) -> int | None:
        if first == 0:
            return second
        if second == 0:
            return first
        if nodes[first][0] > nodes[second][0]:
            first, second = second, first
        key, left, right, _, _ = nodes[first]
        copied = allocate((key, left, right, 0, 0))
        if copied is None:
            return None
        merged_right = meld(right, second)
        if merged_right is None:
            return None
        right = merged_right
        if nodes[left][3] < nodes[right][3]:
            left, right = right, left
        npl = nodes[right][3] + 1
        size = nodes[left][4] + nodes[right][4] + 1
        nodes[copied] = (key, left, right, npl, size)
        return copied

    roots = [0]
    sizes = [0]
    observed_sum = 0
    observed_xor = 0

    for kind, *args in operations:
        if kind == 0:
            base, key = args
            if sizes[base] + 1 > MAX_HEAP_SIZE:
                return -1
            singleton = allocate((key, 0, 0, 1, 1))
            if singleton is None:
                return -1
            root = meld(roots[base], singleton)
        elif kind == 1:
            left_version, right_version = args
            if sizes[left_version] + sizes[right_version] > MAX_HEAP_SIZE:
                return -1
            root = meld(roots[left_version], roots[right_version])
        elif kind == 2:
            (version,) = args
            old_root = roots[version]
            rank = nodes[old_root][0] + MAX_KEY if old_root else EMPTY_RANK
            observed_sum += rank
            observed_xor ^= rank
            root = meld(nodes[old_root][1], nodes[old_root][2]) if old_root else 0
        else:
            (version,) = args
            old_root = roots[version]
            rank = nodes[old_root][0] + MAX_KEY if old_root else EMPTY_RANK
            observed_sum += rank
            observed_xor ^= rank
            root = old_root

        if root is None:
            return -1
        root_size = nodes[root][4] if root else 0
        if root_size > MAX_HEAP_SIZE:
            return -1
        roots.append(root)
        sizes.append(root_size)

    result = (observed_sum << 15) | observed_xor
    return result if result <= MAX_RESULT else -1
