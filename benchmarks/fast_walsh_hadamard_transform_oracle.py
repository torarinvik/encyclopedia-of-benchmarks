"""Direct O(n^2) oracle for the bounded XOR Walsh-Hadamard transform."""
MAX_LENGTH = 128
MAX_ABS_VALUE = 10_000

def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_LENGTH + 2
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    inverse, n = values[:2]
    if inverse not in (0, 1) or n < 1 or n > MAX_LENGTH or n & (n - 1) or len(values) != n + 2:
        return -1, b""
    seq = values[2:]
    if any(abs(x) > MAX_ABS_VALUE for x in seq):
        return -1, b""
    transformed = [sum(value if (bin(index & j).count("1") & 1) == 0 else -value
                       for j, value in enumerate(seq)) for index in range(n)]
    if inverse:
        if any(value % n for value in transformed):
            return -1, b""
        transformed = [value // n for value in transformed]
    import struct
    return n, b"".join(struct.pack("<q", value) for value in transformed)
