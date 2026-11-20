"""Inverse-rank reference for the bounded Cupif-Giannini leaf order."""

MAX_H = 6
MAX_FRAME_WORDS = 3


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    # Validate the call frame locally instead of importing the primary oracle.
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    frame_size = len(values)
    if frame_size < 2 or frame_size > MAX_FRAME_WORDS:
        return -1, b""
    if input_length is not None and frame_size != input_length:
        return -1, b""
    if frame_size != 2:
        return -1, b""
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63)
           for word in values):
        return -1, b""

    h, permutation_key = values
    if h < 0 or h > MAX_H:
        return -1, b""
    leaf_count = 1 << h
    if permutation_key < 0 or permutation_key >= leaf_count:
        return -1, b""

    needed = leaf_count
    if output_is_null or (capacity is not None and capacity < needed):
        return -2, b""

    # Enumerate each low-bit-first path code and scatter it into the count
    # that selects it. This inverts the visit order instead of simulating it.
    by_visit_rank = [0] * leaf_count
    for path_code in range(leaf_count):
        count = path_code ^ permutation_key
        by_visit_rank[count] = path_code

    payload = bytes(by_visit_rank)
    return needed, payload
