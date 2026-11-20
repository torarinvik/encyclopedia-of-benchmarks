"""Interval-weight reference; it tracks depths without constructing a tree."""

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_MAX = (1 << 64) - 1
MIN_SYMBOLS = 2
MAX_SYMBOLS = 8
MIN_WEIGHT = 1
MAX_WEIGHT = 15
MAX_TOTAL_WEIGHT = 120
MAX_DEPTH = 7
MAX_COST = 840
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 2048


def _pack(words):
    result = bytearray()
    for value in words:
        result.extend(value.to_bytes(8, byteorder="little", signed=True))
    return bytes(result)


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or (input_length is not None and (type(input_length) is not int or not 0 <= input_length <= SIZE_MAX))
            or (capacity is not None and (type(capacity) is not int or not 0 <= capacity <= SIZE_MAX))):
        return -1, b""
    if input_is_null:
        no_storage = values is None or (isinstance(values, (list, tuple)) and len(values) == 0)
        if no_storage and input_length in (None, 0):
            return -1, b""
        return -1, b""
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or len(values) > MAX_VALID_INPUT_LENGTH):
        return -1, b""
    for value in values:
        if type(value) is not int or value < I64_MIN or value > I64_MAX:
            return -1, b""
    count = values[0]
    if not MIN_SYMBOLS <= count <= MAX_SYMBOLS or len(values) != count + 1:
        return -1, b""
    masses = list(values[1:])
    if any(not MIN_WEIGHT <= mass <= MAX_WEIGHT for mass in masses) or sum(masses) > MAX_TOTAL_WEIGHT:
        return -1, b""

    # Each active item is (first leaf, last leaf, combined weight).
    blocks = [(i, i, mass) for i, mass in enumerate(masses)]
    depth_vector = [0 for _ in masses]
    while len(blocks) > 1:
        pair = 0
        least_total = blocks[0][2] + blocks[1][2]
        cursor = 1
        while cursor < len(blocks) - 1:
            total = blocks[cursor][2] + blocks[cursor + 1][2]
            if total < least_total:
                pair, least_total = cursor, total
            cursor += 1
        first = blocks[pair]
        second = blocks[pair + 1]
        for leaf in range(first[0], second[1] + 1):
            depth_vector[leaf] += 1
        joined = (first[0], second[1], least_total)
        blocks = blocks[:pair] + [joined] + blocks[pair + 2:]

    weighted_depth = 0
    for i in range(count):
        weighted_depth += masses[i] * depth_vector[i]
    payload = _pack([count, weighted_depth] + depth_vector)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
