"""Full-position recomputation reference for Zobrist hash traces."""

SQUARES = 16
KINDS = 3
MAX_EDITS = 64
HEADER_SIZE = 1 + SQUARES * KINDS + SQUARES
FRAME_LIMIT = HEADER_SIZE + 2 * MAX_EDITS + 1


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    # Keep contract validation local so the second reference does not import
    # helpers or normalization rules from the incremental reference.
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1, b""
    words = len(values)
    if words < HEADER_SIZE or words > FRAME_LIMIT:
        return -1, b""
    if input_length is not None and input_length != words:
        return -1, b""
    if any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
           for item in values):
        return -1, b""

    count = values[0]
    if count < 0 or count > MAX_EDITS:
        return -1, b""
    if words != HEADER_SIZE + 2 * count:
        return -1, b""

    key_start = 1
    slot_start = key_start + SQUARES * KINDS
    move_start = slot_start + SQUARES
    feature_keys = tuple(values[key_start:slot_start])
    if any(value < 0 for value in feature_keys):
        return -1, b""
    position = list(values[slot_start:move_start])
    if any(value not in (0, 1, 2, 3) for value in position):
        return -1, b""
    changes = []
    for record in range(count):
        square = values[move_start + record * 2]
        replacement = values[move_start + record * 2 + 1]
        if square not in range(SQUARES) or replacement not in range(KINDS + 1):
            return -1, b""
        changes.append((square, replacement))

    byte_count = 8 * (count + 1)
    if output_is_null or (capacity is not None and capacity < byte_count):
        return -2, b""

    def fold(position_state):
        acc = 0
        for square, piece in enumerate(position_state):
            if piece != 0:
                acc ^= feature_keys[square * KINDS + piece - 1]
        return acc

    serialized = bytearray(fold(position).to_bytes(8, "little"))
    for square, replacement in changes:
        position[square] = replacement
        serialized.extend(fold(position).to_bytes(8, "little"))
    return byte_count, bytes(serialized)
