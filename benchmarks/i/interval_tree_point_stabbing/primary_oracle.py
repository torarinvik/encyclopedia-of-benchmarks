"""Static balanced max-high interval tree for bounded point-stabbing queries."""

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_MAX = (1 << 64) - 1
MIN_INTERVALS = 0
MAX_INTERVALS = 16
MIN_QUERIES = 0
MAX_QUERIES = 8
MIN_COORDINATE = -32
MAX_COORDINATE = 32
MAX_VALID_INPUT_LENGTH = 42
MAX_PARSEABLE_INPUT_LENGTH = 43
MAX_OUTPUT_BYTES = 72
WORKSPACE_BYTES = 4096


def _encode(words):
    return b"".join(word.to_bytes(8, "little", signed=True) for word in words)


def _tree_answers(intervals, queries):
    ordered = sorted((lo, hi, ident) for ident, (lo, hi) in enumerate(intervals))
    n = len(ordered)
    left = [-1] * n
    right = [-1] * n
    maximum = [-(1 << 63)] * n
    frames = [(0, n - 1, -1, 0)] if n else []
    root = -1
    while frames:
        low, high, parent, side = frames.pop()
        if low > high:
            continue
        mid = (low + high) // 2
        if parent < 0:
            root = mid
        elif side == 0:
            left[parent] = mid
        else:
            right[parent] = mid
        if mid + 1 <= high:
            frames.append((mid + 1, high, mid, 1))
        if low <= mid - 1:
            frames.append((low, mid - 1, mid, 0))

    traversal = [root] if root >= 0 else []
    order = []
    while traversal:
        node = traversal.pop()
        order.append(node)
        if left[node] >= 0:
            traversal.append(left[node])
        if right[node] >= 0:
            traversal.append(right[node])
    for node in reversed(order):
        lo, hi, _ident = ordered[node]
        maximum[node] = hi
        if left[node] >= 0:
            maximum[node] = max(maximum[node], maximum[left[node]])
        if right[node] >= 0:
            maximum[node] = max(maximum[node], maximum[right[node]])

    answers = []
    for point in queries:
        mask = 0
        pending = [root] if root >= 0 else []
        while pending:
            node = pending.pop()
            if maximum[node] < point:
                continue
            lo, hi, ident = ordered[node]
            if left[node] >= 0 and maximum[left[node]] >= point:
                pending.append(left[node])
            if lo <= point <= hi:
                mask |= 1 << ident
            if lo <= point and right[node] >= 0 and maximum[right[node]] >= point:
                pending.append(right[node])
        answers.append(mask)
    return answers


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or (input_length is not None and (type(input_length) is not int or not 0 <= input_length <= SIZE_MAX))
            or (capacity is not None and (type(capacity) is not int or not 0 <= capacity <= SIZE_MAX))):
        return -1, b""
    if input_is_null:
        empty = values is None or (isinstance(values, (list, tuple)) and len(values) == 0)
        if empty and input_length in (None, 0):
            return -1, b""
        return -1, b""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or len(values) < 2 or len(values) > MAX_VALID_INPUT_LENGTH):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n, q = values[0], values[1]
    if not MIN_INTERVALS <= n <= MAX_INTERVALS or not MIN_QUERIES <= q <= MAX_QUERIES:
        return -1, b""
    if len(values) != 2 + 2 * n + q:
        return -1, b""
    intervals = []
    offset = 2
    for _ in range(n):
        lo, hi = values[offset], values[offset + 1]
        if not MIN_COORDINATE <= lo <= MAX_COORDINATE or not MIN_COORDINATE <= hi <= MAX_COORDINATE or lo > hi:
            return -1, b""
        intervals.append((lo, hi))
        offset += 2
    queries = values[offset:]
    if any(not MIN_COORDINATE <= point <= MAX_COORDINATE for point in queries):
        return -1, b""
    output = _encode([q, *_tree_answers(intervals, queries)])
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
