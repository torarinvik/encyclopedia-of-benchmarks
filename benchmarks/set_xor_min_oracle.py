"""Independent Python-set oracle for Library Checker Set XOR-Min."""

import struct

MAX_Q = 64
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_VALUE = 1 << 30


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[Q,(type,x)...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or len(values) < 1):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""
    q = values[0]
    if not 1 <= q <= MAX_Q or len(values) != 1 + 2 * q:
        return -1, b""

    active = set()
    answers = []
    for index in range(q):
        kind, value = values[1 + 2 * index: 3 + 2 * index]
        if kind not in (0, 1, 2) or not 0 <= value < MAX_VALUE:
            return -1, b""
        if kind == 0:
            active.add(value)
        elif kind == 1:
            active.discard(value)
        else:
            if not active:
                return -1, b""
            answers.append(min(member ^ value for member in active))

    required = 8 * len(answers)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
