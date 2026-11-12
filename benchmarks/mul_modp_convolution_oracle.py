"""Primary bounded multiplicative-group transform oracle."""

MOD = 998_244_353
MAX_P = 97
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_P
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_P
MAX_OUTPUT_BYTES = 8 * MAX_P
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _prime(p):
    if p < 2:
        return False
    divisor = 2
    while divisor * divisor <= p:
        if p % divisor == 0:
            return False
        divisor += 1
    return True


def _parse(values):
    if values is None or len(values) < 5 or len(values) > MAX_INPUT_LENGTH:
        return None
    p = values[0]
    if type(p) is not int or not 2 <= p <= MAX_P or not _prime(p):
        return None
    if len(values) != 1 + 2 * p:
        return None
    a, b = values[1:1 + p], values[1 + p:]
    if any(type(x) is not int or not 0 <= x < MOD for x in a + b):
        return None
    return p, a, b


def _primitive_root(p):
    order = p - 1
    factors = []
    value = order
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            factors.append(divisor)
            while value % divisor == 0:
                value //= divisor
        divisor += 1
    if value > 1:
        factors.append(value)
    for candidate in range(1, p):
        if all(pow(candidate, order // factor, p) != 1 for factor in factors):
            return candidate
    return 1


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    p, a, b = parsed
    order = p - 1
    root = _primitive_root(p)
    residue_by_exp = [1] * order
    exp_by_residue = [-1] * p
    residue = 1
    for exponent in range(order):
        residue_by_exp[exponent] = residue
        exp_by_residue[residue] = exponent
        residue = (residue * root) % p

    left = [a[residue_by_exp[e]] for e in range(order)]
    right = [b[residue_by_exp[e]] for e in range(order)]
    cyclic = [0] * order
    for i in range(order):
        for j in range(order):
            slot = (i + j) % order
            cyclic[slot] = (cyclic[slot] + left[i] * right[j]) % MOD

    result = [0] * p
    sum_a = sum(a) % MOD
    sum_b_nonzero = sum(b[1:]) % MOD
    result[0] = (sum_a * b[0] + a[0] * sum_b_nonzero) % MOD
    for exponent, coefficient in enumerate(cyclic):
        result[residue_by_exp[exponent]] = coefficient
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
