"""Direct bounded simulation of the Cupif-Giannini leaf walk."""

MAX_HEIGHT = 6
MAX_VALID_INPUT_LENGTH = 2
MAX_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 128


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or input_length < 0)):
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return -1, b""

    height, key = values
    if not 0 <= height <= MAX_HEIGHT:
        return -1, b""
    leaf_count = 1 << height
    if not 0 <= key < leaf_count:
        return -1, b""

    required = leaf_count
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""

    result = bytearray()
    for count in range(leaf_count):
        path = count ^ key
        leaf_code = 0
        for level in range(height):
            branch = (path >> level) & 1
            leaf_code |= branch << level
        result.append(leaf_code)
    return required, bytes(result)
