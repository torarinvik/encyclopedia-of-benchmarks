"""Mutable flat-slot reference for the deterministic Cuckoo Filter trace."""

BUCKETS = 8
SLOTS_PER_BUCKET = 4
MAX_OPERATIONS = 32
MAX_KICKS = 8
MAX_VALID_INPUT_WORDS = 1 + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
WORKSPACE_BYTES = 1024


def _i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _delta(fingerprint):
    return 1 + ((5 * fingerprint + 3) % 7)


def _first_empty(table, bucket):
    base = bucket * SLOTS_PER_BUCKET
    for slot in range(SLOTS_PER_BUCKET):
        if table[base + slot] == 0:
            return base + slot
    return None


def _insert(table, primary, fingerprint):
    alternate = primary ^ _delta(fingerprint)
    empty = _first_empty(table, primary)
    if empty is not None:
        table[empty] = fingerprint
        return True
    empty = _first_empty(table, alternate)
    if empty is not None:
        table[empty] = fingerprint
        return True

    pending = fingerprint
    current = primary
    for _ in range(MAX_KICKS):
        slot = current * SLOTS_PER_BUCKET
        evicted = table[slot]
        table[slot] = pending
        pending = evicted
        current ^= _delta(pending)
        empty = _first_empty(table, current)
        if empty is not None:
            table[empty] = pending
            return True
    return False


def _run(records):
    table = [0] * (BUCKETS * SLOTS_PER_BUCKET)
    statuses = []
    for opcode, primary, fingerprint in records:
        alternate = primary ^ _delta(fingerprint)
        if opcode == 0:
            if not _insert(table, primary, fingerprint):
                return -3, b""
            statuses.append(1)
        elif opcode == 1:
            found = any(table[bucket * SLOTS_PER_BUCKET + slot] == fingerprint
                        for bucket in (primary, alternate)
                        for slot in range(SLOTS_PER_BUCKET))
            statuses.append(1 if found else 0)
        else:
            removed = False
            for bucket in (primary, alternate):
                base = bucket * SLOTS_PER_BUCKET
                for slot in range(SLOTS_PER_BUCKET):
                    if table[base + slot] == fingerprint:
                        table[base + slot] = 0
                        removed = True
                        break
                if removed:
                    break
            statuses.append(1 if removed else 0)

    payload = b"".join(status.to_bytes(8, "little", signed=True) for status in statuses)
    return len(payload), payload


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
    if not 4 <= length <= MAX_PARSEABLE_INPUT_WORDS:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _i64(word) for word in values):
        return -1, b""

    operation_count = values[0]
    if not 1 <= operation_count <= MAX_OPERATIONS:
        return -1, b""
    if length != 1 + 3 * operation_count:
        return -1, b""
    records = []
    for index in range(operation_count):
        opcode, primary, fingerprint = values[1 + 3 * index:4 + 3 * index]
        if opcode not in (0, 1, 2) or not 0 <= primary < BUCKETS:
            return -1, b""
        if not 1 <= fingerprint <= 15:
            return -1, b""
        records.append((opcode, primary, fingerprint))

    required = 8 * operation_count
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return _run(records)
