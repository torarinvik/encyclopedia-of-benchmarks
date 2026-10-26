"""Independent verifier model for the bounded set-cover profile.

This model uses explicit element-to-winner scans and a separate round update
path from the package oracle.
"""

MAX_SETS = 8
MAX_ELEMENTS = 8
MAX_INPUT_LENGTH = 1 + MAX_SETS
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def model(values):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return None
    set_count = values[0]
    element_count = set_count
    if not 1 <= set_count <= MAX_SETS:
        return None
    if len(values) != set_count + 1:
        return None
    masks = values[1:]
    valid_bits = (1 << element_count) - 1
    if any(row < 0 or row & ~valid_bits for row in masks):
        return None
    for vertex, row in enumerate(masks):
        if row & (1 << vertex):
            return None
        for other in range(set_count):
            if bool(row & (1 << other)) != bool(masks[other] & (1 << vertex)):
                return None
    still_open = [True] * element_count
    selected = [False] * set_count
    bucket_state = [sum((masks[s] >> e) & 1 for e in range(element_count)) for s in range(set_count)]
    pass_index = 0
    while any(still_open):
        highest = max(bucket_state)
        if highest == 0:
            break
        bucket_group = [s for s in range(set_count) if bucket_state[s] == highest]
        residual = [0] * set_count
        contenders = []
        for s in bucket_group:
            residual[s] = sum(1 for e in range(element_count)
                              if still_open[e] and ((masks[s] >> e) & 1))
            bucket_state[s] = residual[s]
            if residual[s] >= highest:
                contenders.append(s)
        ordering = sorted(contenders, key=lambda s: ((s + set_count - pass_index % set_count) % set_count))
        gained = [0] * set_count
        for e in range(element_count):
            if not still_open[e]:
                continue
            owner = -1
            for s in ordering:
                if (masks[s] >> e) & 1:
                    owner = s
                    break
            if owner != -1:
                gained[owner] += 1
        accepted = [s for s in contenders if gained[s] >= highest]
        if not accepted:
            if contenders:
                return None
            pass_index += 1
            continue
        newly_closed = [False] * element_count
        for s in accepted:
            selected[s] = True
            for e in range(element_count):
                if (masks[s] >> e) & 1:
                    newly_closed[e] = True
        still_open = [still_open[e] and not newly_closed[e] for e in range(element_count)]
        for s in accepted:
            bucket_state[s] = 0
        pass_index += 1
    selected_mask = sum((1 << s) for s, yes in enumerate(selected) if yes)
    uncovered_mask = sum((1 << e) for e, yes in enumerate(still_open) if yes)
    return selected_mask, uncovered_mask


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and
            (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_LENGTH)
            or not isinstance(values, (list, tuple))):
        return INVALID_RESULT, b""
    if input_is_null or (input_length is not None and input_length != len(values)):
        return INVALID_RESULT, b""
    result = model(values)
    if result is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    import struct
    return MAX_OUTPUT_BYTES, struct.pack("<qq", *result)


def expected_result(values):
    return expected_output(values)[0]
