"""Direct list-order reference, independent of the primary label scheme."""

INVALID_RESULT = -1
MAX_ELEMENTS = 64
MAX_OPERATIONS = 128
MAX_PARSEABLE_INPUT_LENGTH = 387


def _frame(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    capacity, count = values[:2]
    if (not 0 <= capacity <= MAX_ELEMENTS
            or not 0 <= count <= MAX_OPERATIONS
            or len(values) != 2 + 3 * count):
        return None
    return capacity, count


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _frame(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    capacity, operation_count = parsed
    order = [0]  # 0 is the permanent circular-list sentinel.
    inserted = 0
    checksum = 0
    for operation in range(operation_count):
        offset = 2 + 3 * operation
        opcode, first, second = values[offset:offset + 3]
        if opcode == 0:
            if (inserted >= capacity or first not in order
                    or second != inserted + 1):
                return INVALID_RESULT
            order.insert(order.index(first) + 1, second)
            inserted += 1
        elif opcode == 1:
            if not (1 <= first <= inserted and 1 <= second <= inserted):
                return INVALID_RESULT
            if order.index(first) < order.index(second):
                checksum += (operation + 1)
        else:
            return INVALID_RESULT
    return checksum
