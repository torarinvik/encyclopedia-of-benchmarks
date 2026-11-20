"""Independent active-item multiset reference for hollow heap traces."""

INVALID_RESULT = -1
MAX_OPERATIONS = 64
MAX_ITEMS = 32
MAX_KEY = 1_000_000
MAX_PARSEABLE_INPUT_VALUES = 194


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    operation_count = values[0]
    if (not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 1 + 3 * operation_count
            or len(values) > 193):
        return INVALID_RESULT

    active = {}
    result = 0
    for operation_index in range(operation_count):
        offset = 1 + 3 * operation_index
        opcode, item_id, value = values[offset:offset + 3]
        if opcode == 1:
            if (not 0 <= item_id < MAX_ITEMS or not 0 <= value <= MAX_KEY
                    or item_id in active):
                return INVALID_RESULT
            active[item_id] = value
        elif opcode == 2:
            if (not 0 <= item_id < MAX_ITEMS or item_id not in active
                    or not 0 <= value <= MAX_KEY or value >= active[item_id]):
                return INVALID_RESULT
            active[item_id] = value
        elif opcode == 3:
            if item_id != 0 or value != 0 or not active:
                return INVALID_RESULT
            minimum_id = min(active, key=lambda item: (active[item], item))
            minimum_key = active.pop(minimum_id)
            result += (operation_index + 1) * (minimum_key + 1) + minimum_id
        elif opcode == 4:
            if item_id != 0 or value != 0 or not active:
                return INVALID_RESULT
            minimum_id = min(active, key=lambda item: (active[item], item))
            result += (operation_index + 1) * (active[minimum_id] + 1) + minimum_id
        elif opcode == 5:
            if (not 0 <= item_id < MAX_ITEMS or value != 0
                    or item_id not in active):
                return INVALID_RESULT
            del active[item_id]
        else:
            return INVALID_RESULT
    return result
