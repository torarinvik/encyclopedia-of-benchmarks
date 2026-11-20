"""Immutable bucket-tuple reference for the deterministic Cuckoo Filter trace."""

BUCKET_COUNT = 8
BUCKET_WIDTH = 4
OP_LIMIT = 32
KICK_LIMIT = 8
FRAME_LIMIT = 98
PAYLOAD_LIMIT = 256
WORKSPACE_BYTES = 1024


def _signed_word(value):
    return type(value) is int and -(2 ** 63) <= value < 2 ** 63


def _alternate_delta(tag):
    return ((5 * tag + 3) % 7) + 1


def _empty_slot(bucket):
    for offset, value in enumerate(bucket):
        if value == 0:
            return offset
    return None


def _updated_bucket(bucket, offset, value):
    return tuple(value if index == offset else old
                 for index, old in enumerate(bucket))


def _load(buckets, home, tag):
    peer = home ^ _alternate_delta(tag)
    offset = _empty_slot(buckets[home])
    if offset is not None:
        buckets[home] = _updated_bucket(buckets[home], offset, tag)
        return True
    offset = _empty_slot(buckets[peer])
    if offset is not None:
        buckets[peer] = _updated_bucket(buckets[peer], offset, tag)
        return True

    carry = tag
    location = home
    for _ in range(KICK_LIMIT):
        displaced = buckets[location][0]
        buckets[location] = _updated_bucket(buckets[location], 0, carry)
        carry = displaced
        location ^= _alternate_delta(carry)
        offset = _empty_slot(buckets[location])
        if offset is not None:
            buckets[location] = _updated_bucket(buckets[location], offset, carry)
            return True
    return False


def _trace(records):
    buckets = [tuple(0 for _ in range(BUCKET_WIDTH)) for _ in range(BUCKET_COUNT)]
    answers = []
    for action, home, tag in records:
        peer = home ^ _alternate_delta(tag)
        if action == 0:
            if not _load(buckets, home, tag):
                return -3, b""
            answers.append(1)
        elif action == 1:
            answers.append(int(tag in buckets[home] or tag in buckets[peer]))
        else:
            deleted = False
            for bucket_id in (home, peer):
                offset = next((j for j, value in enumerate(buckets[bucket_id]) if value == tag), None)
                if offset is not None:
                    buckets[bucket_id] = _updated_bucket(buckets[bucket_id], offset, 0)
                    deleted = True
                    break
            answers.append(int(deleted))
    data = b"".join(answer.to_bytes(8, "little", signed=True) for answer in answers)
    return len(data), data


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1, b""
    word_count = len(values)
    if word_count < 4 or word_count > FRAME_LIMIT:
        return -1, b""
    if input_length is not None and input_length != word_count:
        return -1, b""
    if any(not _signed_word(item) for item in values):
        return -1, b""

    count = values[0]
    if count < 1 or count > OP_LIMIT or word_count != 1 + 3 * count:
        return -1, b""
    records = []
    for offset in range(1, word_count, 3):
        action, home, tag = values[offset:offset + 3]
        if action not in (0, 1, 2) or not 0 <= home < BUCKET_COUNT or not 1 <= tag <= 15:
            return -1, b""
        records.append((action, home, tag))
    if output_is_null or (capacity is not None and capacity < count * 8):
        return -2, b""
    return _trace(records)
