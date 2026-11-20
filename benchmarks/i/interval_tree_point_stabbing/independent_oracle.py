"""Independent direct scan for static closed-interval point-stabbing queries."""

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_MAX = (1 << 64) - 1
MAX_INTERVALS = 16
MAX_QUERIES = 8
MAX_VALID_INPUT_LENGTH = 42
MAX_PARSEABLE_INPUT_LENGTH = 43
MAX_OUTPUT_BYTES = 72
WORKSPACE_BYTES = 4096


def _serialize(words):
    payload = bytearray()
    for word in words:
        payload.extend(int(word).to_bytes(8, "little", signed=True))
    return bytes(payload)


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or (input_length is not None and (type(input_length) is not int or input_length < 0 or input_length > SIZE_MAX))
            or (capacity is not None and (type(capacity) is not int or capacity < 0 or capacity > SIZE_MAX))):
        return -1, b""
    if input_is_null:
        if (values is None or (isinstance(values, (list, tuple)) and len(values) == 0)) and input_length in (None, 0):
            return -1, b""
        return -1, b""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_VALID_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(v) is not int or v < I64_MIN or v > I64_MAX for v in values):
        return -1, b""
    count, query_count = values[0], values[1]
    if not 0 <= count <= MAX_INTERVALS or not 0 <= query_count <= MAX_QUERIES:
        return -1, b""
    if len(values) != 2 + 2 * count + query_count:
        return -1, b""
    records = []
    cursor = 2
    for interval_id in range(count):
        start, end = values[cursor], values[cursor + 1]
        if not -32 <= start <= 32 or not -32 <= end <= 32 or start > end:
            return -1, b""
        records.append((interval_id, start, end))
        cursor += 2
    points = values[cursor:]
    if any(not -32 <= point <= 32 for point in points):
        return -1, b""
    answers = []
    for point in points:
        result_mask = 0
        for interval_id, start, end in records:
            if start <= point <= end:
                result_mask |= 1 << interval_id
        answers.append(result_mask)
    payload = _serialize([query_count, *answers])
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
