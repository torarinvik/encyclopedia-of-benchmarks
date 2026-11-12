"""Independent output-index-first verifier for truncated multivariate products."""

MOD = 998_244_353
MAX_K = 3
MAX_PRODUCT = 32
MAX_INPUT_LENGTH = 1 + MAX_K + 2 * MAX_PRODUCT + 1
MAX_OUTPUT_ELEMENTS = MAX_PRODUCT
MAX_OUTPUT_BYTES = 8 * MAX_PRODUCT


def _parse(values):
    if values is None or len(values) < 1 or len(values) > MAX_INPUT_LENGTH:
        return None
    k = values[0]
    if type(k) is not int or k < 0 or k > MAX_K or len(values) < 1 + k:
        return None
    dims = values[1:1 + k]
    product = 1
    for dim in dims:
        if type(dim) is not int or dim < 2:
            return None
        product *= dim
        if product > MAX_PRODUCT:
            return None
    start = 1 + k
    if len(values) != start + 2 * product:
        return None
    f, g = values[start:start + product], values[start + product:]
    if any(type(x) is not int or x < 0 or x >= MOD for x in f + g):
        return None
    return dims, product, f, g


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
    dims, product, f, g = parsed
    f_coords = [_coordinates(i, dims) for i in range(product)]
    g_coords = [_coordinates(i, dims) for i in range(product)]
    result = [0] * product
    for target in range(product):
        target_coords = _coordinates(target, dims)
        total = 0
        for i in range(product):
            for j in range(product):
                if all(f_coords[i][axis] + g_coords[j][axis] == target_coords[axis]
                       for axis in range(len(dims))):
                    total = (total + f[i] * g[j]) % MOD
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
