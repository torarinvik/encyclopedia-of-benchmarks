"""Incremental Divide-and-Combine construction for bounded permutations."""

from __future__ import annotations

MAX_N = 16
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 2
MAX_STRONG_INTERVALS = 2 * MAX_N - 1
MAX_RESULT = MAX_STRONG_INTERVALS * (MAX_STRONG_INTERVALS + 1) // 2 * (
    MAX_N * (MAX_N + 1) + MAX_N
)


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null:
        return None
    try:
        data = tuple(values)
    except TypeError:
        return None
    length = len(data) if input_length is None else input_length
    if (type(length) is not int or length < 1
            or length > MAX_PARSEABLE_INPUT_LENGTH or length != len(data)):
        return None
    if type(data[0]) is not int or not 1 <= data[0] <= MAX_N:
        return None
    n = data[0]
    if length != n + 1:
        return None
    permutation = data[1:]
    if (any(type(value) is not int or not 0 <= value < n
            for value in permutation)
            or len(set(permutation)) != n):
        return None
    return n, permutation


def _incremental_intervals(permutation):
    n = len(permutation)
    levels = n.bit_length()
    minimum = [[0] * n for _ in range(levels)]
    maximum = [[0] * n for _ in range(levels)]
    minimum[0] = list(permutation)
    maximum[0] = list(permutation)
    for level in range(1, levels):
        half = 1 << (level - 1)
        width = half << 1
        for start in range(n - width + 1):
            minimum[level][start] = min(
                minimum[level - 1][start], minimum[level - 1][start + half]
            )
            maximum[level][start] = max(
                maximum[level - 1][start], maximum[level - 1][start + half]
            )

    def connected(left, right):
        width = right - left + 1
        level = width.bit_length() - 1
        span = 1 << level
        low = min(minimum[level][left], minimum[level][right - span + 1])
        high = max(maximum[level][left], maximum[level][right - span + 1])
        return high - low == right - left

    tree_min = [0] * (4 * n + 4)
    lazy = [0] * (4 * n + 4)

    def add(node, left, right, query_left, query_right, delta):
        if query_left <= left and right <= query_right:
            tree_min[node] += delta
            lazy[node] += delta
            return
        middle = (left + right) // 2
        if lazy[node]:
            tag = lazy[node]
            tree_min[node * 2] += tag
            tree_min[node * 2 + 1] += tag
            lazy[node * 2] += tag
            lazy[node * 2 + 1] += tag
            lazy[node] = 0
        if query_left <= middle and query_right >= left:
            add(node * 2, left, middle, query_left, query_right, delta)
        if query_right > middle and query_left <= right:
            add(node * 2 + 1, middle + 1, right,
                query_left, query_right, delta)
        tree_min[node] = min(tree_min[node * 2], tree_min[node * 2 + 1])

    def first_zero(node, left, right):
        if left == right:
            return left
        middle = (left + right) // 2
        if tree_min[node * 2] == 0:
            return first_zero(node * 2, left, middle)
        return first_zero(node * 2 + 1, middle + 1, right)

    left_endpoint = []
    right_endpoint = []
    is_combine = []
    last_child_left = []
    node_stack = []
    minimum_stack = []
    maximum_stack = []

    def new_node(left, right, combine=False, last_left=0):
        node = len(left_endpoint)
        left_endpoint.append(left)
        right_endpoint.append(right)
        is_combine.append(combine)
        last_child_left.append(last_left)
        return node

    for end, value in enumerate(permutation):
        while minimum_stack and permutation[minimum_stack[-1]] >= value:
            position = minimum_stack.pop()
            start = minimum_stack[-1] + 1 if minimum_stack else 0
            add(1, 0, n - 1, start, position,
                permutation[position])
        while maximum_stack and permutation[maximum_stack[-1]] <= value:
            position = maximum_stack.pop()
            start = maximum_stack[-1] + 1 if maximum_stack else 0
            add(1, 0, n - 1, start, position,
                -permutation[position])

        start = minimum_stack[-1] + 1 if minimum_stack else 0
        add(1, 0, n - 1, start, end, -value)
        minimum_stack.append(end)
        start = maximum_stack[-1] + 1 if maximum_stack else 0
        add(1, 0, n - 1, start, end, value)
        maximum_stack.append(end)

        leftmost = first_zero(1, 0, n - 1)
        current = new_node(end, end)
        while node_stack and left_endpoint[node_stack[-1]] >= leftmost:
            top = node_stack[-1]
            if (is_combine[top]
                    and connected(last_child_left[top], end)):
                right_endpoint[top] = end
                last_child_left[top] = left_endpoint[current]
                current = node_stack.pop()
            elif connected(left_endpoint[top], end):
                merged = new_node(
                    left_endpoint[top], end, True, left_endpoint[current]
                )
                node_stack.pop()
                current = merged
            else:
                while node_stack:
                    node_stack.pop()
                    if node_stack and connected(left_endpoint[node_stack[-1]], end):
                        break
                if not node_stack:
                    raise AssertionError("incremental merge lost its connected base")
                base = node_stack.pop()
                merged = new_node(left_endpoint[base], end)
                current = merged
        node_stack.append(current)
        add(1, 0, n - 1, 0, end, -1)

    return [(left_endpoint[node], right_endpoint[node])
            for node in range(len(left_endpoint))]


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, permutation = parsed
    intervals = sorted(_incremental_intervals(permutation))
    if len(intervals) > MAX_STRONG_INTERVALS:
        raise AssertionError("construction exceeded the strong-interval bound")
    return sum(
        rank * ((left + 1) * (n + 1) + (right + 1))
        for rank, (left, right) in enumerate(intervals, 1)
    )
