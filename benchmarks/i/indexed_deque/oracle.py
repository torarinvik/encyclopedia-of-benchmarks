"""List-based reference for indexed double-ended operation traces."""


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list)) or not values
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    q = values[0]
    if not (1 <= q <= 256 and len(values) == 1 + 2*q):
        return -1, b""
    items, answers = [], []
    for i in range(q):
        op, arg = values[1+2*i:3+2*i]
        if op in (0, 1):
            if not -1_000_000 <= arg <= 1_000_000 or len(items) == 256:
                return -1, b""
            if op == 0:
                items.insert(0, arg)
            else:
                items.append(arg)
        elif op in (2, 3):
            if arg != 0 or not items:
                return -1, b""
            items.pop(0 if op == 2 else -1)
        elif op == 4:
            if not 0 <= arg < len(items):
                return -1, b""
            answers.append(items[arg])
        else:
            return -1, b""
    if not answers:
        return -1, b""
    size = 8 * len(answers)
    if output_is_null or (capacity is not None and capacity < size):
        return -2, b""
    return size, b"".join(x.to_bytes(8, "little", signed=True) for x in answers)
