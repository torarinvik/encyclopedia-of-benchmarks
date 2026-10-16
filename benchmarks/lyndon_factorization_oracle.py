"""Oracle for bounded lowercase-ASCII Lyndon factorization."""

MAX_SEQUENCE_LENGTH = 256
MAX_INPUT_LENGTH = MAX_SEQUENCE_LENGTH + 1
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def _factor(data: bytes) -> bytes:
    factors = bytearray()
    start = 0
    n = len(data)
    while start < n:
        candidate = start + 1
        match = start
        while candidate < n and data[match] <= data[candidate]:
            if data[match] < data[candidate]:
                match = start
            else:
                match += 1
            candidate += 1
        length = candidate - match
        while start <= match:
            factors.extend(data[start:start + length])
            factors.append(0)
            start += length
    return bytes(factors)


def expected_output(values, output_capacity=None):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    count = values[0]
    data = values[1:]
    if (not 0 <= count <= MAX_SEQUENCE_LENGTH or len(data) != count
            or any(not 97 <= value <= 122 for value in data)):
        return INVALID_RESULT, b""
    output = _factor(bytes(data))
    if output_capacity is not None and output_capacity < 2 * count:
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
