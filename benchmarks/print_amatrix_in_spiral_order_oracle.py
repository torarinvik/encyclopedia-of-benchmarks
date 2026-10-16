"""Runtime oracle for bounded clockwise matrix spiral traversal."""
MAX_ROWS = 8
MAX_COLS = 8
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLS
INVALID_RESULT = -1

def expected_result(values):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(x) is not int for x in values):
        return INVALID_RESULT
    rows, cols = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS or len(values) != 2 + rows * cols:
        return INVALID_RESULT
    flat = values[2:]
    if any(not -(1 << 31) <= x < (1 << 31) for x in flat):
        return INVALID_RESULT
    top, bottom, left, right = 0, rows - 1, 0, cols - 1
    order = []
    while top <= bottom and left <= right:
        for c in range(left, right + 1): order.append(flat[top * cols + c])
        top += 1
        for r in range(top, bottom + 1): order.append(flat[r * cols + right])
        right -= 1
        if top <= bottom:
            for c in range(right, left - 1, -1): order.append(flat[bottom * cols + c])
            bottom -= 1
        if left <= right:
            for r in range(bottom, top - 1, -1): order.append(flat[r * cols + left])
            left += 1
    h = 2166136261
    for x in order:
        u = x & 0xffffffff
        for shift in (0, 8, 16, 24):
            h = ((h ^ ((u >> shift) & 0xff)) * 16777619) & 0xffffffff
    return h
