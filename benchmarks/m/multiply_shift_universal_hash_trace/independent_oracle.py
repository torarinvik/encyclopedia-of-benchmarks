"""Bitwise add-and-double reference for multiply-shift hash traces."""

BITS = 32
HASH_BITS_LIMIT = 16
QUERY_LIMIT = 32
FRAME_LIMIT = 2 + 2 * QUERY_LIMIT
PARSE_LIMIT = FRAME_LIMIT + 1
BYTE_LIMIT = 8 * QUERY_LIMIT
WORD_MODULUS = 1 << BITS
WORD_MASK = WORD_MODULUS - 1
WORKSPACE_BYTES = 128


def _modular_product(left: int, right: int) -> int:
    acc = 0
    addend = left
    remaining = right
    for _ in range(BITS):
        if remaining & 1:
            acc = (acc + addend) & WORD_MASK
        addend = (addend << 1) & WORD_MASK
        remaining >>= 1
    return acc


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    # Keep all contract checks independent of the widened-product reference.
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1, b""
    count_words = len(values)
    if count_words < 2 or count_words > PARSE_LIMIT:
        return -1, b""
    if input_length is not None and input_length != count_words:
        return -1, b""
    for word in values:
        if type(word) is not int or word < -(1 << 63) or word >= (1 << 63):
            return -1, b""

    width = values[0]
    count = values[1]
    if width == 0 or width > HASH_BITS_LIMIT or width < 0:
        return -1, b""
    if count < 0 or count > QUERY_LIMIT:
        return -1, b""
    if count_words != 2 + 2 * count:
        return -1, b""

    encoded_queries = []
    for pos in range(2, count_words, 2):
        seed = values[pos]
        key = values[pos + 1]
        if seed <= 0 or seed >= WORD_MODULUS or seed % 2 == 0:
            return -1, b""
        if key < 0 or key >= WORD_MODULUS:
            return -1, b""
        encoded_queries.append((seed, key))

    byte_count = count * 8
    if ((output_is_null and byte_count > 0)
            or (capacity is not None and capacity < byte_count)):
        return -2, b""

    shift_count = BITS - width
    result = bytearray()
    for seed, key in encoded_queries:
        word = _modular_product(seed, key) >> shift_count
        result += int(word).to_bytes(8, byteorder="little", signed=False)
    return byte_count, bytes(result)
