"""Independent direct-list oracle for the bounded hash-heap trace."""
from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_MAX = (1 << 64) - 1
MAX_U = 128
MAX_B = 8
MAX_Q = 64
MAX_FRAME = 3 + 2 * MAX_Q + 1
MAX_BYTES = 8 * (MAX_Q + 1)


def _valid(values, input_length):
    if not isinstance(values, (tuple, list)) or len(values) < 3 or len(values) > MAX_FRAME:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return None
    universe, buckets, count = values[:3]
    if universe < 1 or universe > MAX_U or buckets < 1 or buckets > min(MAX_B, universe):
        return None
    if count < 0 or count > MAX_Q or len(values) != 3 + 2 * count:
        return None
    for index in range(count):
        opcode, operand = values[3 + 2 * index:5 + 2 * index]
        if opcode == 0:
            if operand < 0 or operand >= universe:
                return None
        elif opcode == 1 or opcode == 2:
            if operand != 0:
                return None
        else:
            return None
    return universe, count


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and
            (type(capacity) is not int or not 0 <= capacity <= SIZE_MAX)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= SIZE_MAX)):
        return -1, b""
    if input_is_null:
        return -1, b""
    parsed = _valid(values, input_length)
    if parsed is None:
        return -1, b""
    _universe, count = parsed
    live: list[tuple[int, int]] = []
    words = [count]
    for operation_index in range(count):
        opcode = values[3 + 2 * operation_index]
        operand = values[4 + 2 * operation_index]
        if opcode == 0:
            live.append((operand, operation_index))
            words.append(-2)
        elif not live:
            words.append(-1)
        else:
            key, origin = min(live)
            words.append((origin << 8) | key)
            if opcode == 2:
                live.remove((key, origin))
    output = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    required = len(output)
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""
    return required, output
