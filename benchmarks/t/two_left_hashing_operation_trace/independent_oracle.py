"""Nested-list reference for 2-left hashing, independent of the node-pool model."""

HALF_SIZE = 8
OP_LIMIT = 40
KEY_LIMIT = 63
FRAME_LIMIT = 162
PAYLOAD_LIMIT = 640
WORKSPACE_BYTES = 2048


def _word(value):
    return type(value) is int and -(2 ** 63) <= value < 2 ** 63


def _decode(values, declared_length):
    if not isinstance(values, (tuple, list)):
        return None
    nwords = len(values)
    if nwords < 5 or nwords > FRAME_LIMIT:
        return None
    if declared_length is not None and (type(declared_length) is not int or declared_length != nwords):
        return None
    if not all(_word(word) for word in values):
        return None
    operations = values[0]
    if operations < 1 or operations > OP_LIMIT or nwords != 1 + 4 * operations:
        return None
    rows = []
    key_locations = {}
    for p in range(1, nwords, 4):
        op, key, left, right = values[p:p + 4]
        if op not in (0, 1, 2) or not 0 <= key <= KEY_LIMIT:
            return None
        if not 0 <= left < HALF_SIZE or not 0 <= right < HALF_SIZE:
            return None
        pair = (left, right)
        if key in key_locations and key_locations[key] != pair:
            return None
        key_locations[key] = pair
        rows.append((op, key, left, right))
    return rows


def _simulate(rows):
    tables = [ [[] for _ in range(HALF_SIZE)], [[] for _ in range(HALF_SIZE)] ]
    output = []
    live = 0
    for op, key, left, right in rows:
        left_chain = tables[0][left]
        right_chain = tables[1][right]
        if op == 0:
            if key in left_chain or key in right_chain:
                output.extend((0, -1))
                continue
            if live == 32:
                return -3, b""
            if len(left_chain) <= len(right_chain):
                left_chain.append(key)
                output.extend((1, 0))
            else:
                right_chain.append(key)
                output.extend((1, 1))
            live += 1
        elif op == 1:
            output.extend((int(key in left_chain or key in right_chain), -1))
        else:
            if key in left_chain:
                left_chain.remove(key)
                live -= 1
                output.extend((1, -1))
            elif key in right_chain:
                right_chain.remove(key)
                live -= 1
                output.extend((1, -1))
            else:
                output.extend((0, -1))
    encoded = b"".join(int(value).to_bytes(8, "little", signed=True) for value in output)
    return len(encoded), encoded


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
    rows = _decode(values, input_length)
    if rows is None:
        return -1, b""
    required = 16 * len(rows)
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return _simulate(rows)
