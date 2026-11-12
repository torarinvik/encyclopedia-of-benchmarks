"""Primary monotone-minima oracle for bounded convex/arbitrary min-plus convolution."""

MAX_N = 32
MAX_M = 32
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + MAX_M
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_N + MAX_M - 1
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _parse(values):
    if values is None or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return None
    n, m = values[0], values[1]
    if type(n) is not int or type(m) is not int or not (1 <= n <= MAX_N and 1 <= m <= MAX_M):
        return None
    if len(values) != 2 + n + m:
        return None
    a = values[2:2 + n]
    b = values[2 + n:]
    if any(type(x) is not int or not 0 <= x <= MAX_VALUE for x in a + b):
        return None
    if any(a[i + 1] - a[i] > a[i + 2] - a[i + 1] for i in range(n - 2)):
        return None
    return a, b


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    a, b = parsed
    n, m = len(a), len(b)
    count = n + m - 1
    result = [0] * count

    def solve(left, right, opt_left, opt_right):
        if left > right:
            return
        mid = (left + right) // 2
        low = max(opt_left, 0, mid - (n - 1))
        high = min(opt_right, m - 1, mid)
        best_value = None
        best_j = low
        for j in range(low, high + 1):
            candidate = a[mid - j] + b[j]
            if best_value is None or candidate < best_value:
                best_value, best_j = candidate, j
        result[mid] = best_value
        solve(left, mid - 1, opt_left, best_j)
        solve(mid + 1, right, best_j, opt_right)

    solve(0, count - 1, 0, m - 1)
    raw = b"".join(value.to_bytes(8, "little", signed=True) for value in result)
    return len(raw), raw


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    try:
        actual_length = len(values)
    except TypeError:
        return -1, b""
    if input_length is not None and input_length != actual_length:
        return -1, b""
    written, raw = evaluate(values)
    if written < 0:
        return written, raw
    if output_is_null or capacity is not None and capacity < written:
        return -2, b""
    return written, raw
