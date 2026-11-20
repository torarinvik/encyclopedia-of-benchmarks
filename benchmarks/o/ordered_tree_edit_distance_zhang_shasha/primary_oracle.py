"""Bounded Zhang--Shasha ordered tree edit distance reference."""

from __future__ import annotations

MAX_NODES = 8
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
MAX_LABEL = 3
INF = 1_000_000


def parse_input(values: list[int]) -> tuple[list[int], list[list[int]], list[int], list[list[int]]] | None:
    if not isinstance(values, list) or not 6 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    n1, n2 = values[0], values[1]
    if not (1 <= n1 <= MAX_NODES and 1 <= n2 <= MAX_NODES):
        return None
    if len(values) != 2 + 2 * n1 + 2 * n2:
        return None
    pos = 2
    trees: list[tuple[list[int], list[list[int]]]] = []
    for n in (n1, n2):
        labels = values[pos:pos + n]
        pos += n
        parents = values[pos:pos + n]
        pos += n
        if any(type(x) is not int or x < 0 or x > MAX_LABEL for x in labels):
            return None
        if parents[0] != -1:
            return None
        children = [[] for _ in range(n)]
        stack = [0]
        for vertex in range(1, n):
            parent = parents[vertex]
            if type(parent) is not int or parent < 0 or parent >= vertex:
                return None
            while stack and stack[-1] != parent:
                stack.pop()
            if not stack:
                return None
            children[parent].append(vertex)
            stack.append(vertex)
        trees.append((labels, children))
    return trees[0][0], trees[0][1], trees[1][0], trees[1][1]


def _postorder(labels: list[int], children: list[list[int]]) -> tuple[list[int], list[int]]:
    vertices: list[int] = []
    leftmost: list[int] = [0]

    def visit(vertex: int) -> int:
        first = 0
        for child in children[vertex]:
            child_left = visit(child)
            if first == 0:
                first = child_left
        vertices.append(vertex)
        post_id = len(vertices)
        leftmost.append(first if first != 0 else post_id)
        return leftmost[post_id]

    visit(0)
    post_labels = [0] + [labels[vertex] for vertex in vertices]
    return post_labels, leftmost


def _tree_distance(labels_a: list[int], children_a: list[list[int]],
                   labels_b: list[int], children_b: list[list[int]]) -> int:
    a, left_a = _postorder(labels_a, children_a)
    b, left_b = _postorder(labels_b, children_b)
    n, m = len(a) - 1, len(b) - 1
    key_a: dict[int, int] = {}
    key_b: dict[int, int] = {}
    for index in range(1, n + 1):
        key_a[left_a[index]] = index
    for index in range(1, m + 1):
        key_b[left_b[index]] = index
    keyroots_a = sorted(key_a.values())
    keyroots_b = sorted(key_b.values())
    tree_dist = [[0] * (m + 1) for _ in range(n + 1)]

    for root_a in keyroots_a:
        for root_b in keyroots_b:
            start_a = left_a[root_a]
            start_b = left_b[root_b]
            forest = [[INF] * (m + 1) for _ in range(n + 1)]
            forest[start_a - 1][start_b - 1] = 0
            for x in range(start_a, root_a + 1):
                forest[x][start_b - 1] = forest[x - 1][start_b - 1] + 1
            for y in range(start_b, root_b + 1):
                forest[start_a - 1][y] = forest[start_a - 1][y - 1] + 1
            for x in range(start_a, root_a + 1):
                for y in range(start_b, root_b + 1):
                    remove = forest[x - 1][y] + 1
                    insert = forest[x][y - 1] + 1
                    if left_a[x] == start_a and left_b[y] == start_b:
                        rename = forest[x - 1][y - 1] + (a[x] != b[y])
                        value = min(remove, insert, rename)
                        forest[x][y] = value
                        tree_dist[x][y] = value
                    else:
                        prefix_a = left_a[x] - 1
                        prefix_b = left_b[y] - 1
                        match_subtrees = forest[prefix_a][prefix_b] + tree_dist[x][y]
                        forest[x][y] = min(remove, insert, match_subtrees)
    return tree_dist[n][m]


def expected_result(values: list[int]) -> int:
    parsed = parse_input(values)
    if parsed is None:
        return -1
    return _tree_distance(*parsed)
