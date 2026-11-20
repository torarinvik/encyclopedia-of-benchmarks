"""Max-plus heavy-light reference for dynamic tree MWIS."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 64
MAX_UPDATES = 64
MAX_WEIGHT = 1_000_000
MAX_OUTPUT_BYTES = 8 * MAX_UPDATES
NEG = -(1 << 60)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual = len(values) if input_length is None else input_length
    if type(actual) is not int or actual != len(values) or actual < 2:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= q <= MAX_UPDATES:
        return None
    edge_end = 2 + n + 2 * (n - 1)
    if actual != edge_end + 2 * q:
        return None
    weights = list(values[2:2 + n])
    if any(not 0 <= w <= MAX_WEIGHT for w in weights):
        return None
    edges = []
    dsu = list(range(n))

    def find(x: int) -> int:
        while dsu[x] != x:
            dsu[x] = dsu[dsu[x]]
            x = dsu[x]
        return x

    for edge in range(n - 1):
        u, v = values[2 + n + 2 * edge: 4 + n + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        ru, rv = find(u), find(v)
        if ru == rv:
            return None
        dsu[ru] = rv
        edges.append((u, v))
    if any(find(v) != find(0) for v in range(n)):
        return None
    updates = []
    for i in range(q):
        vertex, weight = values[edge_end + 2 * i:edge_end + 2 * i + 2]
        if not 0 <= vertex < n or not 0 <= weight <= MAX_WEIGHT:
            return None
        updates.append((vertex, weight))
    return n, weights, edges, updates


def _mul(a: tuple[int, int, int, int], b: tuple[int, int, int, int]):
    out = []
    for row in range(2):
        for col in range(2):
            out.append(max(a[row * 2 + k] + b[k * 2 + col] for k in range(2)))
    return tuple(out)


def _run(n: int, weights: list[int], edges: list[tuple[int, int]], updates: list[tuple[int, int]]):
    adjacency = [[] for _ in range(n)]
    for u, v in edges:
        adjacency[u].append(v)
        adjacency[v].append(u)
    parent = [-2] * n
    parent[0] = -1
    order = [0]
    for u in order:
        for v in adjacency[u]:
            if parent[v] == -2:
                parent[v] = u
                order.append(v)
    size = [1] * n
    heavy = [-1] * n
    f0 = [0] * n
    f1 = [0] * n
    for u in reversed(order):
        best_size = 0
        for v in adjacency[u]:
            if parent[v] == u:
                size[u] += size[v]
                if size[v] > best_size:
                    best_size, heavy[u] = size[v], v
                f0[u] += max(f0[v], f1[v])
                f1[u] += f0[v]
        f1[u] += weights[u]

    head = [-1] * n
    position = [-1] * n
    tail = [-1] * n
    chain_heads = [0]
    clock = 0
    while chain_heads:
        h = chain_heads.pop()
        u = h
        while u != -1:
            head[u], position[u] = h, clock
            clock += 1
            tail[h] = u
            for v in adjacency[u]:
                if parent[v] == u and v != heavy[u]:
                    chain_heads.append(v)
            u = heavy[u]

    light0 = [0] * n
    light1 = list(weights)
    for u in range(n):
        for v in adjacency[u]:
            if parent[v] == u and v != heavy[u]:
                light0[u] += max(f0[v], f1[v])
                light1[u] += f0[v]
    matrices = [(light0[u], light0[u], light1[u], NEG) for u in range(n)]
    identity = (0, NEG, NEG, 0)
    base = 1
    while base < n:
        base *= 2
    tree = [identity] * (2 * base)
    for u in range(n):
        tree[base + position[u]] = matrices[u]
    for i in range(base - 1, 0, -1):
        tree[i] = _mul(tree[2 * i], tree[2 * i + 1])

    def set_matrix(u: int, matrix: tuple[int, int, int, int]) -> None:
        i = base + position[u]
        tree[i] = matrix
        i //= 2
        while i:
            tree[i] = _mul(tree[2 * i], tree[2 * i + 1])
            i //= 2

    def chain_summary(h: int) -> tuple[int, int]:
        left, right = base + position[h], base + position[tail[h]] + 1
        before = after = identity
        while left < right:
            if left & 1:
                before = _mul(before, tree[left])
                left += 1
            if right & 1:
                right -= 1
                after = _mul(tree[right], after)
            left //= 2
            right //= 2
        product = _mul(before, after)
        return max(product[0], product[1]), max(product[2], product[3])

    answers = []
    for vertex, new_weight in updates:
        h = head[vertex]
        old0, old1 = chain_summary(h)
        delta = new_weight - weights[vertex]
        weights[vertex] = new_weight
        m = matrices[vertex]
        matrices[vertex] = (m[0], m[1], m[2] + delta, m[3])
        set_matrix(vertex, matrices[vertex])
        new0, new1 = chain_summary(h)
        while parent[h] != -1:
            p = parent[h]
            parent_head = head[p]
            before0, before1 = chain_summary(parent_head)
            pm = matrices[p]
            delta0 = max(new0, new1) - max(old0, old1)
            delta1 = new0 - old0
            matrices[p] = (pm[0] + delta0, pm[1] + delta0, pm[2] + delta1, pm[3])
            set_matrix(p, matrices[p])
            old0, old1 = before0, before1
            new0, new1 = chain_summary(parent_head)
            h = parent_head
        root0, root1 = chain_summary(0)
        answers.append(max(root0, root1))
    return answers


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, weights, edges, updates = parsed
    required = 8 * len(updates)
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is None:
        capacity = MAX_OUTPUT_BYTES
    elif type(output_capacity) is not int or output_capacity < 0:
        return -2, b""
    else:
        capacity = output_capacity
    if required and (output_is_null or capacity < required):
        return -2, b""
    answers = _run(n, weights, edges, updates)
    return required, b"".join(value.to_bytes(8, "little", signed=True) for value in answers)
