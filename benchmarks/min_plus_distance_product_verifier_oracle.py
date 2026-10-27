"""Independent column-oriented verifier for the distance product."""

INF = 1_000_000
MAX_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 512


def verify(a):
    if a is None or len(a) < 4 or len(a) > 130:
        return -1, b""
    n, m = a[0], a[1]
    if not isinstance(n, int) or n < 1 or n > 8 or not isinstance(m, int) or m < 1 or m > 8:
        return -1, b""
    if len(a) != 2 + 2*n*m:
        return -1, b""
    split = 2+n*m
    rows_a = [a[2+i*m:2+(i+1)*m] for i in range(n)]
    rows_b = [a[split+i*n:split+(i+1)*n] for i in range(m)]
    if any(not isinstance(x,int) or x < 0 or (x > 1000 and x != INF) for row in rows_a+rows_b for x in row):
        return -1, b""
    answer = []
    for row in rows_a:
        for j in range(n):
            candidates = []
            for k, left in enumerate(row):
                right = rows_b[k][j]
                if left != INF and right != INF:
                    candidates.append(left+right)
            answer.append(min(candidates) if candidates else INF)
    raw = b"".join(x.to_bytes(8,"little",signed=True) for x in answer)
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
    written, raw = verify(a)
    if written < 0:
        return written, raw
    if output_is_null or capacity is not None and capacity < written:
        return -2, b""
    return written, raw
