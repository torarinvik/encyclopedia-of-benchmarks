"""Shared bounded oracle for pinned Python rotate_matrix operations."""
MAX_ROWS = 32
MAX_COLS = 32
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLS
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_ROWS * MAX_COLS)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

def transform(rows, cols, values, operation):
    out_rows, out_cols = (cols, rows) if operation != "rotate_180" else (rows, cols)
    out = [0] * (out_rows * out_cols)
    for r in range(rows):
        for c in range(cols):
            if operation == "rotate_90": rr, cc = cols - 1 - c, r
            elif operation == "rotate_180": rr, cc = rows - 1 - r, cols - 1 - c
            elif operation == "rotate_270": rr, cc = c, rows - 1 - r
            else: rr, cc = c, r
            out[rr * out_cols + cc] = values[r * cols + c]
    return out_rows, out_cols, out

def expected_output(values, operation, capacity=None):
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return -1, b""
    rows, cols = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS or len(values) != 2 + rows * cols:
        return -1, b""
    if operation not in {"rotate_90", "rotate_180", "rotate_270", "transpose"}: return -1, b""
    out_rows, out_cols, cells = transform(rows, cols, values[2:], operation)
    output = b"".join(x.to_bytes(8, "little", signed=True) for x in [out_rows, out_cols, *cells])
    if capacity is not None and (type(capacity) is not int or capacity < 0): return -1, b""
    if capacity is not None and capacity < len(output): return -2, b""
    return len(output), output
