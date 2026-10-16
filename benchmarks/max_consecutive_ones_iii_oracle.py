"""Bounded oracle for the pinned Max Consecutive Ones III sliding window."""
INVALID_RESULT = -2
MAX_ARRAY_LENGTH = 1024
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 2

def expected_result(values):
    if not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return INVALID_RESULT
    n, k, *bits = values
    if not 1 <= n <= MAX_ARRAY_LENGTH or len(bits) != n or not 0 <= k <= n or any(bit not in (0, 1) for bit in bits):
        return INVALID_RESULT
    left = zeros = best = 0
    for right, bit in enumerate(bits):
        zeros += bit == 0
        while zeros > k:
            zeros -= bits[left] == 0
            left += 1
        best = max(best, right - left + 1)
    return best
