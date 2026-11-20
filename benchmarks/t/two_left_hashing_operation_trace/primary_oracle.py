"""Bounded linked-node-pool reference for the 2-left hashing trace."""

BUCKETS_PER_HALF = 8
MAX_OPERATIONS = 40
MAX_LIVE_KEYS = 32
MAX_VALID_INPUT_WORDS = 1 + 4 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 2 * 8 * MAX_OPERATIONS
WORKSPACE_BYTES = 2048


def _is_i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _parse(values, input_length):
    if not isinstance(values, (list, tuple)):
        return None
    size = len(values)
    if not 5 <= size <= MAX_PARSEABLE_INPUT_WORDS:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != size):
        return None
    if any(not _is_i64(value) for value in values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_OPERATIONS or size != 1 + 4 * count:
        return None
    records = []
    for i in range(count):
        op, key, left, right = values[1 + 4 * i:5 + 4 * i]
        if op not in (0, 1, 2) or not 0 <= key <= 63:
            return None
        if not 0 <= left < BUCKETS_PER_HALF or not 0 <= right < BUCKETS_PER_HALF:
            return None
        for prior_op, prior_key, prior_left, prior_right in records:
            if prior_key == key and (prior_left != left or prior_right != right):
                return None
        records.append((op, key, left, right))
    return records


def _find(heads, next_nodes, keys, bucket, key):
    node = heads[bucket]
    while node >= 0:
        if keys[node] == key:
            return node
        node = next_nodes[node]
    return -1


def _encode(statuses, placements):
    words = []
    for status, placement in zip(statuses, placements):
        words.extend((status, placement))
    payload = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    return len(payload), payload


def _run(records):
    heads = [-1] * (2 * BUCKETS_PER_HALF)
    lengths = [0] * (2 * BUCKETS_PER_HALF)
    keys = [-1] * MAX_LIVE_KEYS
    next_nodes = [-1] * MAX_LIVE_KEYS
    statuses = []
    placements = []
    live = 0

    for op, key, left, right in records:
        left_bucket = left
        right_bucket = BUCKETS_PER_HALF + right
        left_node = _find(heads, next_nodes, keys, left_bucket, key)
        right_node = _find(heads, next_nodes, keys, right_bucket, key)

        if op == 0:
            if left_node >= 0 or right_node >= 0:
                statuses.append(0)
                placements.append(-1)
                continue
            if live >= MAX_LIVE_KEYS:
                return -3, b""
            use_left = lengths[left_bucket] <= lengths[right_bucket]
            bucket = left_bucket if use_left else right_bucket
            node = next(index for index, value in enumerate(keys) if value < 0)
            keys[node] = key
            next_nodes[node] = heads[bucket]
            heads[bucket] = node
            lengths[bucket] += 1
            live += 1
            statuses.append(1)
            placements.append(0 if use_left else 1)
        elif op == 1:
            statuses.append(1 if left_node >= 0 or right_node >= 0 else 0)
            placements.append(-1)
        else:
            bucket = left_bucket if left_node >= 0 else right_bucket
            target = left_node if left_node >= 0 else right_node
            if target < 0:
                statuses.append(0)
            else:
                previous = -1
                node = heads[bucket]
                while node != target:
                    previous = node
                    node = next_nodes[node]
                if previous < 0:
                    heads[bucket] = next_nodes[target]
                else:
                    next_nodes[previous] = next_nodes[target]
                keys[target] = -1
                next_nodes[target] = -1
                lengths[bucket] -= 1
                live -= 1
                statuses.append(1)
            placements.append(-1)

    return _encode(statuses, placements)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null:
        return -1, b""
    records = _parse(values, input_length)
    if records is None:
        return -1, b""
    required = len(records) * 16
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return _run(records)
