"""Primary oracle for one bounded min-plus distance-matrix product."""

INF = 1_000_000
MAX_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 512


def _parse(a):
    if a is None or len(a) < 4 or len(a) > MAX_INPUT_LENGTH:
        return None
    n, m = a[0], a[1]
    if not isinstance(n, int) or not 1 <= n <= 8 or not isinstance(m, int) or not 1 <= m <= 8:
        return None
    if len(a) != 2 + 2*n*m:
        return None
    entries = a[2:]
    if any(not isinstance(x, int) or (x < 0 or x > 1000 and x != INF) for x in entries):
        return None
    return n, m, entries[:n*m], entries[n*m:]


def evaluate(a):
    parsed = _parse(a)
    if parsed is None:
        return -1, b""
    n, m, left, right = parsed
    result = []
    for i in range(n):
        for j in range(n):
            best = INF
            for k in range(m):
                x = left[i*m+k]
                y = right[k*n+j]
                if x != INF and y != INF and x+y < best:
                    best = x+y
            result.append(best)
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    return len(raw), raw


def expected_output(a, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or a is None:
        return -1, b""
    try:
        actual_length = len(a)
    except TypeError:
        return -1, b""
    if input_length is not None and input_length != actual_length:
        return -1, b""
    written, raw = evaluate(a)
    if written < 0:
        return written, raw
    if output_is_null or capacity is not None and capacity < written:
        return -2, b""
    return written, raw
