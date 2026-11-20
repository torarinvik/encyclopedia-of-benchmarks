"""Rebuilding residual-term IBLT oracle; does not mutate cell fields."""

VERTEX_COUNT = 48
SUBTABLE_WIDTH = 16
SET_LIMIT = 8
KEY_LIMIT = 63
FRAME_BOUND = 19
PEEL_BOUND = 16
OUTPUT_BOUND = 152
WORKSPACE_BYTES = 2048


def _word_is_i64(word):
    return type(word) is int and -(2 ** 63) <= word < 2 ** 63


def _bucket_tuple(value):
    return (value % 16, 16 + ((3 * value + 5) % 16), 32 + ((5 * value + 9) % 16))


def _check_tag(value):
    return value * (value + 3) + 7


def _form_cells(base_terms, corrections):
    counts = [0] * VERTEX_COUNT
    sums = [0] * VERTEX_COUNT
    tags = [0] * VERTEX_COUNT
    for polarity, key in base_terms + corrections:
        tag = _check_tag(key)
        for bucket in _bucket_tuple(key):
            counts[bucket] += polarity
            sums[bucket] += polarity * key
            tags[bucket] += polarity * tag
    return counts, sums, tags


def _scan_rebuilt_terms(first_keys, second_keys):
    base_terms = [(1, key) for key in first_keys]
    base_terms.extend((-1, key) for key in second_keys)
    corrections = []
    positive = []
    negative = []
    repeated = False

    for _ in range(PEEL_BOUND):
        counts, sums, tags = _form_cells(base_terms, corrections)
        if not any(counts) and not any(sums) and not any(tags):
            break
        selected = None
        for bucket in range(VERTEX_COUNT):
            polarity = counts[bucket]
            if polarity not in (1, -1):
                continue
            key = polarity * sums[bucket]
            if 0 <= key <= KEY_LIMIT and tags[bucket] == polarity * _check_tag(key):
                selected = (polarity, key)
                break
        if selected is None:
            break
        polarity, key = selected
        if key in positive or key in negative:
            repeated = True
            break
        (positive if polarity > 0 else negative).append(key)
        corrections.append((-polarity, key))

    counts, sums, tags = _form_cells(base_terms, corrections)
    complete = not repeated and not any(counts) and not any(sums) and not any(tags)
    words = [1 if complete else 0, len(positive), len(negative)]
    words += sorted(positive)
    words += sorted(negative)
    output = b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)
    return len(output), output


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
    size = len(values)
    if size < 2 or size > FRAME_BOUND:
        return -1, b""
    if input_length is not None and input_length != size:
        return -1, b""
    if any(not _word_is_i64(item) for item in values):
        return -1, b""

    a_count, b_count = values[0], values[1]
    if a_count < 0 or a_count > SET_LIMIT or b_count < 0 or b_count > SET_LIMIT:
        return -1, b""
    if size != 2 + a_count + b_count:
        return -1, b""
    a_keys = list(values[2:2 + a_count])
    b_keys = list(values[2 + a_count:])
    for sequence in (a_keys, b_keys):
        if any(key < 0 or key > KEY_LIMIT for key in sequence):
            return -1, b""
        if any(sequence[index - 1] >= sequence[index] for index in range(1, len(sequence))):
            return -1, b""

    required, encoded = _scan_rebuilt_terms(a_keys, b_keys)
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return required, encoded
