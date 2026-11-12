"""Bounded direct residue-pair oracle for multiplicative convolution mod 2**N."""

MOD = 998_244_353
MAX_N = 5
MAX_P = 1 << MAX_N
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_P
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_P
MAX_OUTPUT_BYTES = 8 * MAX_P
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _parse(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_N:
        return None
    p = 1 << n
    if len(values) != 1 + 2 * p:
        return None
    a = values[1:1 + p]
    b = values[1 + p:]
    if any(type(x) is not int or not 0 <= x < MOD for x in a + b):
        return None
    return p, a, b


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    p, a, b = parsed
    mask = p - 1
    result = [0] * p
    for i in range(p):
        for j in range(p):
            slot = (i * j) & mask
            result[slot] = (result[slot] + a[i] * b[j]) % MOD
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
