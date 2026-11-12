"""Independent output-index-first verifier for cyclic multivariate products."""

MAX_P = 97
MAX_K = 3
MAX_PRODUCT = 32
MAX_INPUT_LENGTH = 2 + MAX_K + 2 * MAX_PRODUCT + 1
MAX_OUTPUT_ELEMENTS = MAX_PRODUCT
MAX_OUTPUT_BYTES = 8 * MAX_PRODUCT


def _parse(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    p, k = values[0], values[1]
    if type(p) is not int or p < 2 or p > MAX_P:
        return None
    d = 2
    while d * d <= p:
        if p % d == 0:
            return None
        d += 1
    if type(k) is not int or k < 0 or k > MAX_K or len(values) < 2 + k:
        return None
    dims = values[2:2 + k]
    product = 1
    for dim in dims:
        if type(dim) is not int or dim < 2 or (p - 1) % dim != 0:
            return None
        product *= dim
        if product > MAX_PRODUCT:
            return None
    start = 2 + k
    if len(values) != start + 2 * product:
        return None
    f, g = values[start:start + product], values[start + product:]
    if any(type(x) is not int or x < 0 or x >= p for x in f + g):
        return None
    return p, dims, product, f, g


def _coordinates(index, dims):
    out = []
    for dim in dims:
        out.append(index % dim)
        index //= dim
    return out


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    p, dims, product, f, g = parsed
    f_coords = [_coordinates(i, dims) for i in range(product)]
    g_coords = [_coordinates(i, dims) for i in range(product)]
    result = [0] * product
    for target in range(product):
        target_coords = _coordinates(target, dims)
        total = 0
        for i in range(product):
            for j in range(product):
                if all((f_coords[i][axis] + g_coords[j][axis]) % dims[axis]
                       == target_coords[axis] for axis in range(len(dims))):
                    total = (total + f[i] * g[j]) % p
        result[target] = total
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
