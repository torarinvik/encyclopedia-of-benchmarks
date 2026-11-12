"""Primary bounded direct-index oracle for cyclic multivariate products."""

MAX_P = 97
MAX_K = 3
MAX_PRODUCT = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_K + 2 * MAX_PRODUCT
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_PRODUCT
MAX_OUTPUT_BYTES = 8 * MAX_PRODUCT
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _prime(p):
    if p < 2:
        return False
    d = 2
    while d * d <= p:
        if p % d == 0:
            return False
        d += 1
    return True


def _parse(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    p, k = values[0], values[1]
    if type(p) is not int or not 2 <= p <= MAX_P or not _prime(p):
        return None
    if type(k) is not int or not 0 <= k <= MAX_K or len(values) < 2 + k:
        return None
    dims = values[2:2 + k]
    product = 1
    for dim in dims:
        if type(dim) is not int or dim < 2 or (p - 1) % dim != 0:
            return None
        product *= dim
        if product > MAX_PRODUCT:
            return None
    if len(values) != 2 + k + 2 * product:
        return None
    start = 2 + k
    f, g = values[start:start + product], values[start + product:]
    if any(type(x) is not int or not 0 <= x < p for x in f + g):
        return None
    return p, dims, product, f, g


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    p, dims, product, f, g = parsed
    result = [0] * product
    for i in range(product):
        for j in range(product):
            target = 0
            stride = 1
            for dim in dims:
                coordinate_sum = ((i // stride) % dim + (j // stride) % dim) % dim
                target += coordinate_sum * stride
                stride *= dim
            result[target] = (result[target] + f[i] * g[j]) % p
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
