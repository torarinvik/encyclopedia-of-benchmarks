"""Direct substring enumeration model; not a suffix automaton."""


def expected_output(values, capacity=256, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None and input_length != len(values))
            or not 3 <= len(values) <= 259
            or any(type(value) is not int for value in values)):
        return -1, b""
    n, k = values[:2]
    if (not 1 <= n <= 256 or len(values) != n + 2 or k < 1
            or any(not 0 <= byte <= 255 for byte in values[2:])):
        return -1, b""
    data = bytes(values[2:])
    substrings = sorted({data[start:end] for start in range(n)
                         for end in range(start + 1, n + 1)})
    if k > len(substrings):
        return -1, b""
    result = substrings[k - 1]
    if output_is_null or capacity < len(result):
        return -2, b""
    return len(result), result
