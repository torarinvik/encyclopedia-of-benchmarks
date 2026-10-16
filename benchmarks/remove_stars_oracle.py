"""Bounded ASCII oracle for the pinned Java removeStars routine."""
MAX_INPUT_LENGTH = 4096

def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH + 1
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return -1, b""
    n = values[0]
    if n < 0 or n > MAX_INPUT_LENGTH or len(values) != n + 1:
        return -1, b""
    text = values[1:]
    if any(c < 0 or c > 127 for c in text):
        return -1, b""
    stack = bytearray()
    for c in text:
        if c == 42:
            if stack:
                stack.pop()
        else:
            stack.append(c)
    return len(stack), bytes(stack)
