"""Direct comparison reference for the bounded BNDM benchmark contract."""


def expected_output(values, input_is_null=False, input_length=None):
    if input_length is not None and not input_is_null and input_length != len(values):
        return -2
    if input_is_null or len(values) < 2:
        return -2
    n, m = values[:2]
    if not (0 <= n <= 4096 and 0 <= m <= 63 and len(values) == 2 + n + m):
        return -2
    if any(value < 97 or value > 122 for value in values[2:]):
        return -2
    text = values[2:2 + n]
    pattern = values[2 + n:]
    for start in range(n - m + 1):
        if text[start:start + m] == pattern:
            return start
    return -1
