"""Runtime oracle for bounded deterministic ISO 10126-2 padding operations."""

MAX_BUFFER_LENGTH = 64
MAX_INPUT_LENGTH = 2 + MAX_BUFFER_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_BUFFER_LENGTH + 1


def expected_output(values, output_capacity=None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    values = list(values)

    def finish(output):
        if output_capacity is not None and output_capacity < len(output):
            return -2, b""
        return len(output), output

    mode = values[0]
    if mode == 0:
        if len(values) < 3:
            return -1, b""
        offset, length = values[1:3]
        if not 1 <= length <= MAX_BUFFER_LENGTH or not 0 <= offset < length:
            return -1, b""
        pad_count = length - offset
        random_count = pad_count - 1
        if len(values) != 3 + offset + random_count:
            return -1, b""
        payload = values[3:3 + offset]
        random_bytes = values[3 + offset:]
        if any(not 0 <= byte <= 255 for byte in payload) or any(not 0 <= byte < 255 for byte in random_bytes):
            return -1, b""
        output = bytes(payload + random_bytes + [pad_count])
        return finish(bytes([pad_count]) + output)
    if mode not in (1, 2) or len(values) < 2:
        return -1, b""
    length = values[1]
    if not 1 <= length <= MAX_BUFFER_LENGTH or len(values) != 2 + length:
        return -1, b""
    data = values[2:]
    if any(not 0 <= byte <= 255 for byte in data):
        return -1, b""
    pad_count = data[-1]
    if not 1 <= pad_count <= length:
        return -1, b""
    if mode == 1:
        output = bytes(data[:length - pad_count])
    else:
        output = bytes([pad_count])
    return finish(output)
