"""In-place signed-cell IBLT reference for a fixed keys-only profile."""

MAX_SET_SIZE = 8
MAX_KEY = 63
MAX_INPUT_WORDS = 2 + 2 * MAX_SET_SIZE
MAX_PARSEABLE_INPUT_WORDS = MAX_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = (3 + 2 * MAX_SET_SIZE) * 8
SUBTABLE_SIZE = 16
CELL_COUNT = 3 * SUBTABLE_SIZE
MAX_PEELS = 2 * MAX_SET_SIZE
WORKSPACE_BYTES = 2048


def _i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _locations(key):
    return (key % 16, 16 + (3 * key + 5) % 16, 32 + (5 * key + 9) % 16)


def _checksum(key):
    return key * key + 3 * key + 7


def _is_pure(count, key_sum, check_sum):
    if count != 1 and count != -1:
        return None
    sign = count
    key = sign * key_sum
    if not 0 <= key <= MAX_KEY or check_sum != sign * _checksum(key):
        return None
    return sign, key


def _encode(complete, positive, negative):
    words = [1 if complete else 0, len(positive), len(negative)]
    words.extend(sorted(positive))
    words.extend(sorted(negative))
    payload = bytearray()
    for word in words:
        payload.extend(word.to_bytes(8, "little", signed=True))
    return len(payload), bytes(payload)


def _peel_in_place(first, second):
    count = [0] * CELL_COUNT
    key_sum = [0] * CELL_COUNT
    check_sum = [0] * CELL_COUNT
    for sign, keys in ((1, first), (-1, second)):
        for key in keys:
            check = _checksum(key)
            for slot in _locations(key):
                count[slot] += sign
                key_sum[slot] += sign * key
                check_sum[slot] += sign * check

    positive = []
    negative = []
    repeated = False
    for _ in range(MAX_PEELS):
        if not any(count) and not any(key_sum) and not any(check_sum):
            break
        candidate = None
        for slot in range(CELL_COUNT):
            candidate = _is_pure(count[slot], key_sum[slot], check_sum[slot])
            if candidate is not None:
                break
        if candidate is None:
            break
        sign, key = candidate
        if key in positive or key in negative:
            repeated = True
            break
        (positive if sign > 0 else negative).append(key)
        key_check = _checksum(key)
        for slot in _locations(key):
            count[slot] -= sign
            key_sum[slot] -= sign * key
            check_sum[slot] -= sign * key_check

    complete = (not repeated and not any(count) and not any(key_sum) and not any(check_sum))
    return _encode(complete, positive, negative)


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
    if not 2 <= length <= MAX_PARSEABLE_INPUT_WORDS:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _i64(word) for word in values):
        return -1, b""

    first_count, second_count = values[0], values[1]
    if not 0 <= first_count <= MAX_SET_SIZE or not 0 <= second_count <= MAX_SET_SIZE:
        return -1, b""
    if length != 2 + first_count + second_count:
        return -1, b""
    first = list(values[2:2 + first_count])
    second = list(values[2 + first_count:])
    for keys in (first, second):
        if any(key < 0 or key > MAX_KEY for key in keys):
            return -1, b""
        if any(keys[i - 1] >= keys[i] for i in range(1, len(keys))):
            return -1, b""

    required, encoded = _peel_in_place(first, second)
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return required, encoded
