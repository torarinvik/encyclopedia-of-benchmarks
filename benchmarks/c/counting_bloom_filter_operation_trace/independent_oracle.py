"""History-rebuild reference for the counting Bloom filter trace."""

MAX_OPERATIONS = 64
COUNTER_COUNT = 67
HASH_COUNT = 4
MAX_VALID_INPUT_LENGTH = 129
MAX_PARSEABLE_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 1024


def _is_i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _locations(key):
    base = (17 * key + 3) % COUNTER_COUNT
    stride = (5 * key + 3) % (COUNTER_COUNT - 1) + 1
    return [((base + step * stride) % COUNTER_COUNT) for step in range(HASH_COUNT)]


def _rebuild(events):
    table = [0] * COUNTER_COUNT
    for sign, key in events:
        for location in _locations(key):
            table[location] += sign
    return table


def _pack(results):
    return bytes(results)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _is_i64(value) for value in values):
        return -1, b""
    q = values[0]
    if not 0 <= q <= MAX_OPERATIONS or length != 1 + 2 * q:
        return -1, b""
    for offset in range(1, length, 2):
        if values[offset] not in (0, 1, 2) or not 0 <= values[offset + 1] <= 65535:
            return -1, b""

    need = q
    if output_is_null or (capacity is not None and capacity < need):
        return -2, b""

    # Store signed insertion/deletion events rather than mutable counters.
    events = []
    live = {}
    answers = []
    for offset in range(1, length, 2):
        op, key = values[offset], values[offset + 1]
        if op == 0:
            events.append((1, key))
            live[key] = live.get(key, 0) + 1
            answers.append(1)
        elif op == 1:
            if live.get(key, 0) == 0:
                return -1, b""
            events.append((-1, key))
            if live[key] == 1:
                del live[key]
            else:
                live[key] -= 1
            answers.append(1)
        else:
            rebuilt = _rebuild(events)
            answers.append(int(all(rebuilt[pos] > 0 for pos in _locations(key))))

    payload = _pack(answers)
    if len(payload) != need:
        return -1, b""
    return need, payload
