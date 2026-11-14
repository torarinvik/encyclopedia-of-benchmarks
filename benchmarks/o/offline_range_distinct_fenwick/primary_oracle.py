"""Unexecuted right-endpoint sweep with a Fenwick tree of latest positions."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= 195
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1
    n, q = values[:2]
    if not 1 <= n <= 64 or not 0 <= q <= 64 or len(values) != 2 + n + 2*q:
        return -1
    data = values[2:2+n]
    if any(not 0 <= value <= 255 for value in data):
        return -1
    queries = []
    for i in range(q):
        left, right = values[2+n+2*i:4+n+2*i]
        if not 0 <= left <= right <= n:
            return -1
        queries.append((right, left, i))
    tree = [0] * (n + 1)
    last = [-1] * 256

    def add(position, delta):
        position += 1
        while position <= n:
            tree[position] += delta
            position += position & -position

    def prefix(end):
        total = 0
        while end:
            total += tree[end]
            end -= end & -end
        return total

    cursor = 0
    result = 0
    for right, left, index in sorted(queries):
        while cursor < right:
            value = data[cursor]
            if last[value] >= 0:
                add(last[value], -1)
            add(cursor, 1)
            last[value] = cursor
            cursor += 1
        result += (index + 1) * (prefix(right) - prefix(left))
    return result
