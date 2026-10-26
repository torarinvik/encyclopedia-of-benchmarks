"""Independent dynamic-programming reconstruction of Fibonacci codewords."""
MAX_INPUT_LENGTH = 33
MAX_OUTPUT_BYTES = 960
MAX_OUTPUT_ELEMENTS = 960

WEIGHTS = [1, 2]
while WEIGHTS[-1] + WEIGHTS[-2] <= 1_000_001:
    WEIGHTS.append(WEIGHTS[-1] + WEIGHTS[-2])


def _word(value):
    target = value + 1
    width = 0
    while width + 1 < len(WEIGHTS) and WEIGHTS[width + 1] <= target:
        width += 1
    # Repeatedly subtract the largest available weight to recover the unique Zeckendorf form.
    bits = [0] * (width + 1)
    rem = target
    i = width
    prior_taken = False
    while i >= 0:
        weight = WEIGHTS[i]
        if not prior_taken and weight <= rem:
            bits[i] = 1
            rem -= weight
            prior_taken = True
        else:
            prior_taken = False
        i -= 1
    while len(bits) > 1 and bits[-1] == 0:
        bits.pop()
    return bytes((48 + bit) for bit in bits) + b"1"


def verify(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if n < 1 or n > 32 or len(values) != n + 1 or any(x < 0 or x > 1_000_000 for x in values[1:]):
        return -1, b""
    raw = b"".join(_word(x) for x in values[1:])
    return len(raw), raw
