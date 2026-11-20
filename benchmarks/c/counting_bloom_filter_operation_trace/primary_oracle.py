"""Incremental counter-array reference for a bounded counting Bloom filter."""

MAX_OPERATIONS = 64
COUNTER_COUNT = 67
HASH_COUNT = 4
MAX_VALID_INPUT_LENGTH = 129
MAX_PARSEABLE_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 1024


def _i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _positions(key):
    first = (17 * key + 3) % COUNTER_COUNT
    step = 1 + ((5 * key + 3) % (COUNTER_COUNT - 1))
    return tuple((first + j * step) % COUNTER_COUNT for j in range(HASH_COUNT))


def _encode(statuses):
    return bytes(statuses)


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
    if any(not _i64(value) for value in values):
        return -1, b""
    operations = values[0]
    if not 0 <= operations <= MAX_OPERATIONS or length != 1 + 2 * operations:
        return -1, b""
    for offset in range(1, length, 2):
        opcode, key = values[offset], values[offset + 1]
        if opcode not in (0, 1, 2) or not 0 <= key <= 65535:
            return -1, b""

    needed = operations
    if output_is_null or (capacity is not None and capacity < needed):
        return -2, b""

    counters = [0] * COUNTER_COUNT
    statuses = []
    live = {}
    for offset in range(1, length, 2):
        opcode, key = values[offset], values[offset + 1]
        positions = _positions(key)
        if opcode == 0:
            for position in positions:
                counters[position] += 1
            live[key] = live.get(key, 0) + 1
            statuses.append(1)
        elif opcode == 1:
            # The bounded source contract requires deletion of a live key.
            # This state map is only reference-side precondition bookkeeping.
            if live.get(key, 0) == 0:
                return -1, b""
            for position in positions:
                counters[position] -= 1
            if live[key] == 1:
                del live[key]
            else:
                live[key] -= 1
            statuses.append(1)
        else:
            statuses.append(int(all(counters[position] != 0 for position in positions)))

    payload = _encode(statuses)
    if len(payload) != needed:
        return -1, b""
    return needed, payload
