"""Independent 31-bit membership-map reference for DIET traces."""

import struct

MAX_OPERATIONS = 32
MIN_KEY = -15
MAX_KEY = 15
MAX_VALID_INPUT_WORDS = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
WORKSPACE_BYTES = 128


def _decode(values, input_is_null, input_length):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    size = len(values)
    if not 1 <= size <= MAX_PARSEABLE_INPUT_WORDS:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != size):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or size != 1 + 2 * count:
        return None
    result = []
    for step in range(count):
        op = values[1 + 2 * step]
        key = values[2 + 2 * step]
        if op not in (0, 1, 2) or key < MIN_KEY or key > MAX_KEY:
            return None
        result.append((op, key))
    return result


def _runs(bits):
    count = 0
    inside = False
    for value in bits:
        if value and not inside:
            count += 1
        inside = value
    return count


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    operations = _decode(values, input_is_null, input_length)
    if operations is None:
        return -1, b""
    required = 8 * len(operations)
    if (output_is_null and required != 0) or (capacity is not None and capacity < required):
        return -2, b""

    bits = [False] * (MAX_KEY - MIN_KEY + 1)
    words = []
    for opcode, key in operations:
        offset = key - MIN_KEY
        if opcode == 0:
            bits[offset] = True
        elif opcode == 1:
            bits[offset] = False
        present = 1 if bits[offset] else 0
        cardinality = sum(bits)
        interval_count = _runs(bits)
        words.append(64 * cardinality + 2 * interval_count + present)
    return required, b"".join(struct.pack("<q", word) for word in words)
