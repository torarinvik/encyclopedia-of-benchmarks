"""Direct rotation model for the unexecuted automaton draft."""


def expected_output(values, capacity=256, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None and input_length != len(values))
            or not 2 <= len(values) <= 258
            or any(type(value) is not int for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 256 or len(values) != n + 1:
        return -1, b""
    if any(not 0 <= value <= 255 for value in values[1:]):
        return -1, b""
    if output_is_null or capacity < n:
        return -2, b""
    data = bytes(values[1:])
    return n, min(data[i:] + data[:i] for i in range(n))
