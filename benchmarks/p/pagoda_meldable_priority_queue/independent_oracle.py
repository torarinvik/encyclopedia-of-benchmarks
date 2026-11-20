"""Independent sorted-multiset model for the Pagoda operation trace."""

INVALID_RESULT = -1
MAX_QUEUES = 8
MAX_OPERATIONS = 64
MAX_PRIORITY = 1000
MIN_PRIORITY = -1000
MAX_VALID_INPUT_WORDS = 258
MAX_PARSEABLE_INPUT_WORDS = 259


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT

    queue_count, operation_count = values[:2]
    if (not 1 <= queue_count <= MAX_QUEUES
            or not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 2 + 4 * operation_count
            or len(values) > MAX_VALID_INPUT_WORDS):
        return INVALID_RESULT

    queues = [[] for _ in range(queue_count)]
    inserted = set()
    result = 0
    for operation_index in range(operation_count):
        offset = 2 + 4 * operation_index
        opcode, first, second, priority = values[offset:offset + 4]
        if opcode == 1:
            if (not 0 <= first < queue_count or second != 0
                    or not MIN_PRIORITY <= priority <= MAX_PRIORITY
                    or priority in inserted):
                return INVALID_RESULT
            inserted.add(priority)
            queues[first].append(priority)
        elif opcode == 2:
            if (not 0 <= first < queue_count or not 0 <= second < queue_count
                    or first == second or priority != 0):
                return INVALID_RESULT
            queues[first].extend(queues[second])
            queues[second].clear()
        elif opcode in (3, 4):
            if (not 0 <= first < queue_count or second != 0 or priority != 0
                    or not queues[first]):
                return INVALID_RESULT
            minimum = min(queues[first])
            result += (operation_index + 1) * (minimum + 1001)
            if opcode == 4:
                queues[first].remove(minimum)
        else:
            return INVALID_RESULT
    return result
