"""Widened-product reference for a bounded multiply-shift hash trace."""

WORD_BITS = 32
MAX_OUTPUT_BITS = 16
MAX_QUERIES = 32
MAX_VALID_INPUT_WORDS = 2 + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES
WORKSPACE_BYTES = 128
WORD_MASK = (1 << WORD_BITS) - 1


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 2 <= length <= MAX_PARSEABLE_INPUT_WORDS:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return -1, b""

    output_bits = values[0]
    query_count = values[1]
    if not 1 <= output_bits <= MAX_OUTPUT_BITS:
        return -1, b""
    if not 0 <= query_count <= MAX_QUERIES:
        return -1, b""
    if length != 2 + 2 * query_count:
        return -1, b""

    queries = []
    for query in range(query_count):
        multiplier = values[2 + 2 * query]
        key = values[3 + 2 * query]
        if not 1 <= multiplier <= WORD_MASK or multiplier % 2 == 0:
            return -1, b""
        if not 0 <= key <= WORD_MASK:
            return -1, b""
        queries.append((multiplier, key))

    required = 8 * query_count
    if (output_is_null and required > 0) or (capacity is not None and capacity < required):
        return -2, b""

    shift = WORD_BITS - output_bits
    output = bytearray()
    for multiplier, key in queries:
        product_low = (multiplier * key) & WORD_MASK
        value = product_low >> shift
        output.extend(value.to_bytes(8, "little"))
    return required, bytes(output)
