"""Direct frequency model of bounded dynamic range majority."""

def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    n, q = values[:2]
    if not (1 <= n <= 64 and 1 <= q <= 64 and len(values) == 2+n+3*q): return -1, b""
    data = list(values[2:2+n])
    if any(x < 0 or x > 1_000_000_000 for x in data): return -1, b""
    answers = []
    for i in range(q):
        op, a, b = values[2+n+3*i:5+n+3*i]
        if op == 0 and 0 <= a < n and 0 <= b <= 1_000_000_000:
            data[a] = b
        elif op == 1 and 0 <= a < b <= n:
            counts = {}
            for value in data[a:b]: counts[value] = counts.get(value, 0) + 1
            answers.append(next((value for value, count in counts.items() if 2*count > b-a), -1))
        else: return -1, b""
    if not answers: return -1, b""
    size = 8*len(answers)
    if output_is_null or (capacity is not None and capacity < size): return -2, b""
    return size, b"".join(value.to_bytes(8, "little", signed=True) for value in answers)
