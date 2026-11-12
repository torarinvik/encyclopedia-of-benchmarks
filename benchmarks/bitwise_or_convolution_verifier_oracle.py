"""Independent per-output oracle for bounded bitwise-OR convolution."""

MODULUS = 998_244_353
MAX_N = 8
MAX_SIZE = 1 << MAX_N
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_SIZE
MAX_OUTPUT_BYTES = 8 * MAX_SIZE


def _decode(values, input_length):
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_N:
        return None
    size = 1 << n
    if len(values) != 1 + 2 * size:
        return None
    left = tuple(values[1:1 + size])
    right = tuple(values[1 + size:])
    if any(x < 0 or x >= MODULUS for x in left + right):
        return None
    return size, left, right


def evaluate(values, input_length=None):
    decoded = _decode(values, input_length)
    if decoded is None:
        return -1, b""
    size, left, right = decoded
    output = []
    for target in range(size):
        total = 0
        for i, x in enumerate(left):
            for j, y in enumerate(right):
                if i | j == target:
                    total = (total + x * y) % MODULUS
        output.append(total)
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in output)
    return len(payload), payload


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
                (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        return -1, b""
    written, payload = evaluate(values, input_length)
    if written < 0:
        return written, payload
    if output_is_null or capacity is not None and capacity < written:
        return -2, b""
    return written, payload
