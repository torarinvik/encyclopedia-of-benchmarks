"""Recurrence oracle for the bounded modular q-binomial profile."""

MAX_T = 16
MAX_MODULUS = 31
MAX_N = 16
MAX_PARSEABLE_INPUT_LENGTH = 36
MAX_OUTPUT_BYTES = MAX_T
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def is_prime(value):
    if type(value) is not int or value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def parse_input(values, input_length=None, input_is_null=False):
    """Return (modulus, q, query-pairs) or None when the frame is invalid."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values)
    if input_length is None:
        input_length = actual_length
    if (type(input_length) is not int
            or input_length != actual_length
            or actual_length < 3
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None

    count, modulus, q_value = values[:3]
    if not 1 <= count <= MAX_T or not 2 <= modulus <= MAX_MODULUS:
        return None
    if not is_prime(modulus) or not 0 <= q_value < modulus:
        return None
    if actual_length != 3 + 2 * count:
        return None

    pairs = []
    for index in range(count):
        n_value, k_value = values[3 + 2 * index:5 + 2 * index]
        if (not 0 <= n_value <= MAX_N or not 0 <= k_value <= MAX_N
                or n_value >= modulus or k_value >= modulus):
            return None
        pairs.append((n_value, k_value))
    return modulus, q_value, pairs


def _row_values(max_n, q_value, modulus):
    table = [[0] * (max_n + 1) for _ in range(max_n + 1)]
    table[0][0] = 1
    for n_value in range(1, max_n + 1):
        table[n_value][0] = 1
        for k_value in range(1, n_value + 1):
            left = table[n_value - 1][k_value] if k_value < n_value else 0
            right = (pow(q_value, n_value - k_value, modulus)
                     * table[n_value - 1][k_value - 1])
            table[n_value][k_value] = (left + right) % modulus
    return table


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return (written byte count or error, one residue byte per query)."""
    parsed = parse_input(values, input_length=input_length,
                         input_is_null=input_is_null)
    if parsed is None:
        return -1, b""
    modulus, q_value, pairs = parsed
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -2, b""
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if output_is_null or capacity < len(pairs):
        return -2, b""

    max_n = max(n_value for n_value, _ in pairs)
    table = _row_values(max_n, q_value, modulus)
    output = bytes(
        0 if k_value > n_value else table[n_value][k_value]
        for n_value, k_value in pairs
    )
    return len(output), output
