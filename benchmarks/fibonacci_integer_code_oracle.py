"""Zeckendorf Fibonacci coding for bounded nonnegative integer sequences."""
MAX_INPUT_LENGTH = 33
MAX_OUTPUT_BYTES = 960
MAX_OUTPUT_ELEMENTS = 960

FIB = [1, 2]
while FIB[-1] + FIB[-2] <= 1_000_001:
    FIB.append(FIB[-1] + FIB[-2])


def evaluate(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if not 1 <= n <= 32 or len(values) != n + 1 or any(x < 0 or x > 1_000_000 for x in values[1:]):
        return -1, b""
    out = bytearray()
    for value in values[1:]:
        remaining = value + 1
        top = len(FIB) - 1
        while top > 0 and FIB[top] > remaining:
            top -= 1
        bits = [0] * (top + 1)
        for i in range(top, -1, -1):
            bit = remaining >= FIB[i]
            if bit:
                bits[i] = 1
                remaining -= FIB[i]
        out.extend(49 if bit else 48 for bit in bits)
        out.append(49)
    return len(out), bytes(out)
