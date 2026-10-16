"""Oracle for bounded undirected weighted graphs and minimum spanning forests."""

from __future__ import annotations

MAX_VERTICES = 8
MAX_EDGES = 28
MAX_OPERATIONS = 128
MIN_WEIGHT = -1_000_000
MAX_WEIGHT = 1_000_000
MAX_INPUT_LENGTH = 3 + 3 * MAX_EDGES + 4 * MAX_OPERATIONS
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
INVALID_RESULT = -1


def _byte(hash_value: int, value: int) -> int:
    return ((hash_value ^ (value & 0xFF)) * FNV_PRIME) & MASK64


def _i32(hash_value: int, value: int) -> int:
    bits = value & 0xFFFFFFFF
    for shift in (0, 8, 16, 24):
        hash_value = _byte(hash_value, bits >> shift)
    return hash_value


def _u32(hash_value: int, value: int) -> int:
    for shift in (0, 8, 16, 24):
        hash_value = _byte(hash_value, value >> shift)
    return hash_value


def _valid_endpoint_pair(n: int, u: int, v: int) -> bool:
    return 0 <= u < n and 0 <= v < n and u != v


def _component_count(n: int, present: list[list[bool]]) -> int:
    seen = [False] * n
    count = 0
    for root in range(n):
        if seen[root]:
            continue
        count += 1
        seen[root] = True
        stack = [root]
        while stack:
            node = stack.pop()
            for neighbor in range(n):
                if present[node][neighbor] and not seen[neighbor]:
                    seen[neighbor] = True
                    stack.append(neighbor)
    return count


def _edge_bit_index(n: int, u: int, v: int) -> int:
    if u > v:
        u, v = v, u
    return sum(n - first - 1 for first in range(u)) + (v - u - 1)


def _prim_forest(n: int, present: list[list[bool]], weights: list[list[int]]) -> tuple[int, int]:
    in_forest = [False] * n
    best_weight = [0] * n
    best_parent = [-1] * n
    components = 0
    edge_mask = 0

    for root in range(n):
        if in_forest[root]:
            continue
        components += 1
        in_forest[root] = True
        for neighbor in range(n):
            if present[root][neighbor] and not in_forest[neighbor]:
                best_weight[neighbor] = weights[root][neighbor]
                best_parent[neighbor] = root

        while True:
            selected = -1
            for candidate in range(n):
                if in_forest[candidate] or best_parent[candidate] < 0:
                    continue
                if selected < 0 or best_weight[candidate] < best_weight[selected]:
                    selected = candidate
            if selected < 0:
                break
            parent = best_parent[selected]
            edge_mask |= 1 << _edge_bit_index(n, parent, selected)
            in_forest[selected] = True
            best_parent[selected] = -1
            for neighbor in range(n):
                if (present[selected][neighbor] and not in_forest[neighbor]
                        and (best_parent[neighbor] < 0
                             or weights[selected][neighbor] < best_weight[neighbor])):
                    best_weight[neighbor] = weights[selected][neighbor]
                    best_parent[neighbor] = selected

    return components, edge_mask


def _kruskal_forest(n: int, present: list[list[bool]], weights: list[list[int]]) -> tuple[int, int]:
    parent = list(range(n))
    rank = [0] * n
    components = n
    edge_mask = 0

    def find(node: int) -> int:
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    edges = [
        (weights[u][v], u, v)
        for u in range(n)
        for v in range(u + 1, n)
        if present[u][v]
    ]
    edges.sort()
    for _weight, u, v in edges:
        left_root = find(u)
        right_root = find(v)
        if left_root == right_root:
            continue
        if rank[left_root] < rank[right_root]:
            parent[left_root] = right_root
        elif rank[left_root] > rank[right_root]:
            parent[right_root] = left_root
        else:
            parent[right_root] = left_root
            rank[left_root] += 1
        components -= 1
        edge_mask |= 1 << _edge_bit_index(n, u, v)

    return components, edge_mask


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT

    n, edge_count = values[0], values[1]
    if not 0 <= n <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return INVALID_RESULT
    if edge_count > n * (n - 1) // 2:
        return INVALID_RESULT

    operation_count_index = 2 + 3 * edge_count
    if operation_count_index >= len(values):
        return INVALID_RESULT
    operation_count = values[operation_count_index]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 3 + 3 * edge_count + 4 * operation_count):
        return INVALID_RESULT

    present = [[False] * n for _ in range(n)]
    weights = [[0] * n for _ in range(n)]
    active_weights: set[int] = set()
    for edge in range(edge_count):
        u, v, weight = values[2 + 3 * edge:5 + 3 * edge]
        if (not 0 <= u < v < n or not MIN_WEIGHT <= weight <= MAX_WEIGHT
                or present[u][v] or weight in active_weights):
            return INVALID_RESULT
        present[u][v] = present[v][u] = True
        weights[u][v] = weights[v][u] = weight
        active_weights.add(weight)

    hash_value = FNV_OFFSET
    for operation in range(operation_count):
        offset = operation_count_index + 1 + 4 * operation
        opcode, u, v, weight = values[offset:offset + 4]
        result_code = 0

        if opcode == 0:
            if (not _valid_endpoint_pair(n, u, v)
                    or not MIN_WEIGHT <= weight <= MAX_WEIGHT):
                return INVALID_RESULT
            pair_u, pair_v = (u, v) if u < v else (v, u)
            old_weight = weights[pair_u][pair_v]
            other_weights = active_weights - ({old_weight} if present[pair_u][pair_v] else set())
            if weight in other_weights:
                return INVALID_RESULT
            if present[pair_u][pair_v]:
                active_weights.remove(old_weight)
            present[pair_u][pair_v] = present[pair_v][pair_u] = True
            weights[pair_u][pair_v] = weights[pair_v][pair_u] = weight
            active_weights.add(weight)
        elif opcode == 1:
            if not _valid_endpoint_pair(n, u, v) or weight != 0:
                return INVALID_RESULT
            pair_u, pair_v = (u, v) if u < v else (v, u)
            if present[pair_u][pair_v]:
                active_weights.remove(weights[pair_u][pair_v])
                present[pair_u][pair_v] = present[pair_v][pair_u] = False
                weights[pair_u][pair_v] = weights[pair_v][pair_u] = 0
        elif opcode == 2:
            if not _valid_endpoint_pair(n, u, v) or weight != 0:
                return INVALID_RESULT
            result_code = int(present[u][v])
        elif opcode == 3:
            if u != 0 or v != 0 or weight != 0:
                return INVALID_RESULT
            hash_value = _byte(hash_value, opcode)
            hash_value = _byte(hash_value, result_code)
            hash_value = _byte(hash_value, _component_count(n, present))
            continue
        elif opcode in (4, 5, 6):
            if u != 0 or v != 0 or weight != 0:
                return INVALID_RESULT
            if opcode == 5:
                component_count, edge_mask = _kruskal_forest(n, present, weights)
            else:
                component_count, edge_mask = _prim_forest(n, present, weights)
            hash_value = _byte(hash_value, opcode)
            hash_value = _byte(hash_value, result_code)
            hash_value = _byte(hash_value, component_count)
            hash_value = _u32(hash_value, edge_mask)
            continue
        else:
            return INVALID_RESULT

        hash_value = _byte(hash_value, opcode)
        hash_value = _byte(hash_value, result_code)

    active_edges = [
        (u, v, weights[u][v])
        for u in range(n)
        for v in range(u + 1, n)
        if present[u][v]
    ]
    hash_value = _byte(hash_value, n)
    hash_value = _byte(hash_value, len(active_edges))
    for u, v, weight in active_edges:
        hash_value = _byte(hash_value, u)
        hash_value = _byte(hash_value, v)
        hash_value = _i32(hash_value, weight)

    return hash_value & MASK63
