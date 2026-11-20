"""Bounded Dietz–Sleator-style cyclic-label order-maintenance reference."""

INVALID_RESULT = -1
MAX_ELEMENTS = 64
MAX_OPERATIONS = 128
MAX_VALID_INPUT_LENGTH = 386
MAX_PARSEABLE_INPUT_LENGTH = 387
LABEL_MODULUS = 1 << 31
LABEL_RING = 2 * LABEL_MODULUS
MAX_RESULT = 8253


def _parse(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    element_limit, operation_count = values[:2]
    if (not 0 <= element_limit <= MAX_ELEMENTS
            or not 0 <= operation_count <= MAX_OPERATIONS
            or len(values) != 2 + 3 * operation_count):
        return None
    return element_limit, operation_count


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    element_limit, operation_count = parsed

    labels = [0] * (MAX_ELEMENTS + 1)
    previous = [0] * (MAX_ELEMENTS + 1)
    following = [0] * (MAX_ELEMENTS + 1)
    inserted = 0
    checksum = 0

    def width(left, right):
        difference = (right - left) % LABEL_RING
        if difference == 0:
            return LABEL_MODULUS
        return difference - LABEL_MODULUS if difference > LABEL_MODULUS else difference

    def add_after(anchor, new_id):
        successor = following[anchor]
        if width(labels[anchor], labels[successor]) <= 1:
            middle = successor
            end = following[middle]
            required = 3
            while end != anchor and width(labels[anchor], labels[end]) <= 4 * width(
                    labels[anchor], labels[middle]):
                required += 1
                end = following[end]
                if end == anchor:
                    break
                required += 1
                end = following[end]
                middle = following[middle]

            interval = LABEL_MODULUS if end == anchor else width(labels[anchor], labels[end])
            spacing = interval // required
            value = labels[end]
            cursor = end
            while True:
                if cursor == 0:
                    value = (value + LABEL_MODULUS) % LABEL_RING
                cursor = previous[cursor]
                if cursor == anchor:
                    break
                value = (value - spacing) % LABEL_RING
                labels[cursor] = value

        labels[new_id] = (labels[anchor] +
                          width(labels[anchor], labels[following[anchor]]) // 2) % LABEL_RING
        successor = following[anchor]
        previous[new_id] = anchor
        following[new_id] = successor
        following[anchor] = new_id
        previous[successor] = new_id

    for operation in range(operation_count):
        offset = 2 + 3 * operation
        opcode, first, second = values[offset:offset + 3]
        if opcode == 0:
            if (inserted >= element_limit or first < 0 or first > inserted
                    or second != inserted + 1):
                return INVALID_RESULT
            inserted += 1
            add_after(first, inserted)
        elif opcode == 1:
            if not (1 <= first <= inserted and 1 <= second <= inserted):
                return INVALID_RESULT
            if labels[first] < labels[second]:
                checksum += (operation + 1) * 1
        else:
            return INVALID_RESULT
    return checksum
