"""Independent O(NM) verifier oracle for concave/arbitrary min-plus convolution."""

MAX_N = 32
MAX_M = 32
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + MAX_M
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_N + MAX_M - 1
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS


def _parse(values):
    if values is None or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    n, m = values[0], values[1]
    if type(n) is not int or type(m) is not int or not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    if len(values) != 2 + n + m:
        return None
    a, b = values[2:2 + n], values[2 + n:]
    if any(type(x) is not int or x < 0 or x > MAX_VALUE for x in a + b):
        return None
    if any(a[i + 1] - a[i] < a[i + 2] - a[i + 1] for i in range(n - 2)):
        return None
    return a, b


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    a, b = parsed
    n, m = len(a), len(b)
    result = []
    for k in range(n + m - 1):
        low = max(0, k - (n - 1))
        high = min(m - 1, k)
        result.append(min(a[k - j] + b[j] for j in range(low, high + 1)))
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
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
