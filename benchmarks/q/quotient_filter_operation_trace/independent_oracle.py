"""Abstract multiset oracle for the bounded SQF operation trace."""

MAX_OPERATIONS = 32
MAX_ITEMS = 6
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_OPERATIONS
WORKSPACE_BYTES = 256


def _i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _simulate(records):
    multiplicities = {}
    total = 0
    statuses = bytearray()
    for opcode, fingerprint in records:
        copies = multiplicities.get(fingerprint, 0)
        if opcode == 0:
            if total == MAX_ITEMS:
                statuses.append(2)
            else:
                multiplicities[fingerprint] = copies + 1
                total += 1
                statuses.append(1)
        elif opcode == 1:
            statuses.append(1 if copies else 0)
        elif copies:
            if copies == 1:
                del multiplicities[fingerprint]
            else:
                multiplicities[fingerprint] = copies - 1
            total -= 1
            statuses.append(1)
        else:
            statuses.append(0)
    return len(statuses), bytes(statuses)


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
    if not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _i64(word) for word in values):
        return -1, b""

    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or length != 1 + 2 * count:
        return -1, b""
    records = []
    for index in range(count):
        opcode, fingerprint = values[1 + 2 * index:3 + 2 * index]
        if opcode not in (0, 1, 2) or not 0 <= fingerprint <= 255:
            return -1, b""
        records.append((opcode, fingerprint))

    if output_is_null or (capacity is not None and capacity < count):
        return -2, b""
    return _simulate(records)
