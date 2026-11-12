"""Primary staircase-rectangle oracle for bounded concave/arbitrary convolution."""

MAX_N = 32
MAX_M = 32
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + MAX_M
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_N + MAX_M - 1
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES
SMALL_RECTANGLE_PRODUCT = 1000


def _parse(values):
    if values is None or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return None
    n, m = values[0], values[1]
    if type(n) is not int or type(m) is not int or not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    if len(values) != 2 + n + m:
        return None
    concave, arbitrary = values[2:2 + n], values[2 + n:]
    if any(type(x) is not int or x < 0 or x > MAX_VALUE for x in concave + arbitrary):
        return None
    for i in range(n - 2):
        if concave[i + 1] - concave[i] < concave[i + 2] - concave[i + 1]:
            return None
    return concave, arbitrary


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    concave, arbitrary = parsed
    n, m = len(arbitrary), len(concave)
    height = n + m - 1
    y_min = [max(0, x - m + 1) for x in range(height)]
    y_max = [min(n - 1, x) for x in range(height)]
    x_min = list(range(n))
    x_max = [m - 1 + y for y in range(n)]
    result = [None] * height

    def monotone_block(x1, x2, y1, y2):
        # q increases while y=y2-q decreases; this reverses the concave
        # operand's staircase block to the monotone-minima orientation.
        def rows(left, right, q_left, q_right):
            if left > right:
                return
            mid = (left + right) // 2
            best = None
            best_q = q_left
            for q in range(q_left, q_right + 1):
                y = y2 - q
                value = arbitrary[y] + concave[mid - y]
                if best is None or value < best:
                    best, best_q = value, q
            if result[mid] is None or best < result[mid]:
                result[mid] = best
            rows(left, mid - 1, q_left, best_q)
            rows(mid + 1, right, best_q, q_right)

        rows(x1, x2, 0, y2 - y1)

    def direct_block(x1, x2, y1, y2):
        for x in range(x1, x2 + 1):
            low = max(y_min[x], y1)
            high = min(y_max[x], y2)
            for y in range(low, high + 1):
                value = arbitrary[y] + concave[x - y]
                if result[x] is None or value < result[x]:
                    result[x] = value

    def partition(x1, x2, y1, y2):
        if x1 > x2 or y1 > y2:
            return
        if y_max[x1] >= y2 and y1 >= y_min[x2]:
            monotone_block(x1, x2, y1, y2)
            return
        if (x2 - x1) * (y2 - y1) < SMALL_RECTANGLE_PRODUCT:
            direct_block(x1, x2, y1, y2)
            return
        if x2 - x1 > y2 - y1:
            middle = (x1 + x2) // 2
            left_y2 = min(y_max[middle], y2)
            if y1 <= left_y2:
                partition(x1, middle, y1, left_y2)
            right_y1 = max(y_min[middle], y1)
            if right_y1 <= y2:
                partition(middle + 1, x2, right_y1, y2)
        else:
            middle = (y1 + y2) // 2
            left_x2 = min(x_max[middle], x2)
            if x1 <= left_x2:
                partition(x1, left_x2, y1, middle)
            right_x1 = max(x_min[middle], x1)
            if right_x1 <= x2:
                partition(right_x1, x2, middle + 1, y2)

    partition(0, height - 1, 0, n - 1)
    raw = b"".join(int(value).to_bytes(8, "little", signed=True) for value in result)
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
