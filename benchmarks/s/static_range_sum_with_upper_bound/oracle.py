"""Direct reference for the bounded thresholded range-query draft."""

def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (capacity is not None and (type(capacity) is not int or capacity < 0))
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))):
        return -1, b""
    n, q = values[:2]
    if not (1 <= n <= 64 and 1 <= q <= 64 and len(values) == 2+n+3*q):
        return -1, b""
    numbers = values[2:2+n]
    if any(x < 0 or x > 1_000_000_000 for x in numbers):
        return -1, b""
    answers = []
    for i in range(q):
        lo, hi, limit = values[2+n+3*i:5+n+3*i]
        if not (0 <= lo <= hi <= n and 0 <= limit <= 1_000_000_000):
            return -1, b""
        selected = [v for v in numbers[lo:hi] if v <= limit]
        answers.extend((len(selected), sum(selected)))
    required = 16*q
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return required, b"".join(v.to_bytes(8, "little", signed=True) for v in answers)
