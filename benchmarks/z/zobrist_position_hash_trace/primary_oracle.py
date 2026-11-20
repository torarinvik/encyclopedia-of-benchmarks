"""Incremental reference for the bounded Zobrist position-hash trace."""

SLOTS = 16
FEATURES = 3
MAX_OPERATIONS = 64
BASE_WORDS = 1 + SLOTS * FEATURES + SLOTS
MAX_VALID_INPUT_LENGTH = BASE_WORDS + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_OPERATIONS + 1)
WORKSPACE_BYTES = 128


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or input_length < 0)):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    size = len(values)
    if size < BASE_WORDS or size > MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != size:
        return -1, b""
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63)
           for word in values):
        return -1, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return -1, b""
    if size != BASE_WORDS + 2 * operation_count:
        return -1, b""

    table_begin = 1
    state_begin = table_begin + SLOTS * FEATURES
    operation_begin = state_begin + SLOTS
    keys = values[table_begin:state_begin]
    if any(key < 0 for key in keys):
        return -1, b""
    board = list(values[state_begin:operation_begin])
    if any(feature < 0 or feature > FEATURES for feature in board):
        return -1, b""

    edits = []
    for offset in range(operation_count):
        slot = values[operation_begin + 2 * offset]
        feature = values[operation_begin + 2 * offset + 1]
        if not 0 <= slot < SLOTS or not 0 <= feature <= FEATURES:
            return -1, b""
        edits.append((slot, feature))

    required = 8 * (operation_count + 1)
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""

    current = 0
    for slot, feature in enumerate(board):
        if feature:
            current ^= keys[slot * FEATURES + feature - 1]
    output = bytearray(current.to_bytes(8, "little"))
    for slot, feature in edits:
        old_feature = board[slot]
        if old_feature:
            current ^= keys[slot * FEATURES + old_feature - 1]
        if feature:
            current ^= keys[slot * FEATURES + feature - 1]
        board[slot] = feature
        output.extend(current.to_bytes(8, "little"))
    return required, bytes(output)
