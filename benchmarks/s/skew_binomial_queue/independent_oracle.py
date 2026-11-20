"""Independent active-item reference for skew-binomial queue traces."""

INVALID_RESULT = -1
MAX_OPERATIONS = 64
MAX_ITEMS = 32
MAX_KEY = 1_000_000
MAX_PARSEABLE_INPUT_VALUES = 194


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 1 + 3 * operation_count or len(values) > 193):
        return INVALID_RESULT

    active = {}
    serial = 0
    result = 0
    for operation_index in range(operation_count):
        offset = 1 + 3 * operation_index
        opcode, item_id, key = values[offset:offset + 3]
        if opcode == 1:
            if (not 0 <= item_id < MAX_ITEMS or not 0 <= key <= MAX_KEY
                    or item_id in active):
                return INVALID_RESULT
            active[item_id] = (key, serial)
            serial += 1
        elif opcode in (2, 3):
            if item_id != 0 or key != 0 or not active:
                return INVALID_RESULT
            minimum_id = min(active, key=lambda item: (active[item][0], active[item][1], item))
            minimum_key = active[minimum_id][0]
            result += (operation_index + 1) * (minimum_key + 1) + minimum_id
            if opcode == 3:
                del active[minimum_id]
        else:
            return INVALID_RESULT
    return result
