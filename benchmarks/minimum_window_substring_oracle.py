"""Oracle for the bounded ASCII minimum-window substring benchmark."""

MAX_INPUT_LENGTH = 258
MAX_TEXT_LENGTH = 128


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    n = values[0]
    if not 0 <= n <= MAX_TEXT_LENGTH or len(values) < n + 2:
        return -1, b""
    s = values[1:n + 1]
    m = values[n + 1]
    if not 1 <= m <= MAX_TEXT_LENGTH or len(values) != n + m + 2:
        return -1, b""
    t = values[n + 2:]
    if any(not 0 <= c <= 127 for c in s + t):
        return -1, b""
    need = [0] * 128
    for c in t:
        need[c] += 1
    missing = m
    left = 0
    best_start = 0
    best_len = n + 1
    for right, c in enumerate(s):
        if need[c] > 0:
            missing -= 1
        need[c] -= 1
        while missing == 0:
            length = right - left + 1
            if length < best_len:
                best_start, best_len = left, length
            out_c = s[left]
            need[out_c] += 1
            left += 1
            if need[out_c] > 0:
                missing += 1
    if best_len == n + 1:
        return 0, b""
    result = bytes(s[best_start:best_start + best_len])
    return len(result), result
