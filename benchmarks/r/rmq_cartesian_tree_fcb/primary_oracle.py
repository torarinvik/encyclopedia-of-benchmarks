"""Cartesian-tree to Euler-tour FCB pipeline for bounded static RMQ."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_Q = 64
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_Q + 1
WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values) or len(values) < 2:
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 2 * q:
        return None
    data = list(values[2:2 + n])
    if any(not -1000 <= value <= 1000 for value in data):
        return None
    queries = []
    for at in range(2 + n, len(values), 2):
        left, right = values[at:at + 2]
        if not 0 <= left <= right < n:
            return None
        queries.append((left, right))
    return data, queries


def _fcb_answers(data, queries):
    n = len(data)
    left_child = [-1] * n
    right_child = [-1] * n
    parent = [-1] * n
    stack = []
    for index, value in enumerate(data):
        last = -1
        while stack and data[stack[-1]] > value:
            last = stack.pop()
        if stack:
            right_child[stack[-1]] = index
            parent[index] = stack[-1]
        if last >= 0:
            left_child[index] = last
            parent[last] = index
        stack.append(index)
    root = next(index for index, item in enumerate(parent) if item < 0)

    first = [-1] * n
    euler = [root]
    depth = [0]
    first[root] = 0
    frames = [[root, 0]]
    while frames:
        node, state = frames[-1]
        if state == 0:
            frames[-1][1] = 1
            child = left_child[node]
            if child >= 0:
                euler.append(child)
                depth.append(depth[-1] + 1)
                first[child] = len(euler) - 1
                frames.append([child, 0])
        elif state == 1:
            if left_child[node] >= 0:
                euler.append(node)
                depth.append(depth[-1] - 1)
            frames[-1][1] = 2
            child = right_child[node]
            if child >= 0:
                euler.append(child)
                depth.append(depth[-1] + 1)
                first[child] = len(euler) - 1
                frames.append([child, 0])
            else:
                frames.pop()
        else:
            if right_child[node] >= 0:
                euler.append(node)
                depth.append(depth[-1] - 1)
            frames.pop()

    euler_count = len(euler)
    block_size = max(1, (euler_count.bit_length() - 1) // 2)
    block_count = (euler_count + block_size - 1) // block_size
    micro = {}
    for shape in range(1 << (block_size - 1)):
        relative = [0] * block_size
        for step in range(block_size - 1):
            relative[step + 1] = relative[step] + (1 if (shape >> step) & 1 else -1)
        table = [[0] * block_size for _ in range(block_size)]
        for lo in range(block_size):
            best = lo
            for hi in range(lo, block_size):
                if relative[hi] < relative[best]:
                    best = hi
                table[lo][hi] = best
        micro[shape] = table

    patterns = [0] * block_count
    macro = [[0] * block_count]
    for block in range(block_count):
        base = block * block_size
        end = min(euler_count, base + block_size)
        best = base
        for pos in range(base + 1, end):
            if depth[pos] > depth[pos - 1]:
                patterns[block] |= 1 << (pos - base - 1)
            if depth[pos] < depth[best]:
                best = pos
        macro[0][block] = best
    logs = [0] * (block_count + 1)
    for count in range(2, block_count + 1):
        logs[count] = logs[count // 2] + 1
    level = 1
    while (1 << level) <= block_count:
        previous = macro[-1]
        span = 1 << level
        half = span >> 1
        row = [0] * block_count
        for block in range(block_count - span + 1):
            a, b = previous[block], previous[block + half]
            row[block] = a if depth[a] <= depth[b] else b
        macro.append(row)
        level += 1

    def shallower(a, b):
        return a if depth[a] <= depth[b] else b

    def range_minimum(first_pos, last_pos):
        block_a, block_b = first_pos // block_size, last_pos // block_size
        off_a, off_b = first_pos % block_size, last_pos % block_size
        if block_a == block_b:
            return block_a * block_size + micro[patterns[block_a]][off_a][off_b]
        base_a, base_b = block_a * block_size, block_b * block_size
        len_a = min(block_size, euler_count - base_a)
        best = base_a + micro[patterns[block_a]][off_a][len_a - 1]
        best = shallower(best, base_b + micro[patterns[block_b]][0][off_b])
        if block_b > block_a + 1:
            lo, hi = block_a + 1, block_b - 1
            count = hi - lo + 1
            k = logs[count]
            span = 1 << k
            best = shallower(best, macro[k][lo])
            best = shallower(best, macro[k][hi - span + 1])
        return best

    answers = []
    for lo, hi in queries:
        a, b = first[lo], first[hi]
        if a > b:
            a, b = b, a
        answers.append(euler[range_minimum(a, b)])
    return answers


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None or type(output_is_null) is not bool:
        return -1, b""
    data, queries = decoded
    required = len(queries) + 1
    if (output_is_null or (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < required))):
        return -2, b""
    answers = _fcb_answers(data, queries)
    return required, bytes([len(answers), *answers])


def expected_result(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    return expected_output(values, output_capacity, output_is_null,
                          input_is_null, input_length)[0]
