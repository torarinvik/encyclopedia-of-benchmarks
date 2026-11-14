"""Direct-search reference for bounded fixed-modulus logarithm batches."""


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    p, g, n = values[:3]
    if not (2 <= p <= 4093 and 1 <= g < p and 1 <= n <= 256 and len(values) == n + 3):
        return -1, b""
    if any(p % d == 0 for d in range(2, int(p ** 0.5) + 1)):
        return -1, b""
    if any(target < 1 or target >= p for target in values[3:]):
        return -1, b""
    residue = 1
    for exponent in range(1, p):
        residue = residue * g % p
        if residue == 1 and exponent != p - 1:
            return -1, b""
    if residue != 1:
        return -1, b""
    answers = []
    for target in values[3:]:
        residue = 1
        for exponent in range(p - 1):
            if residue == target:
                answers.append(exponent)
                break
            residue = residue * g % p
    size = 8 * n
    if output_is_null or (capacity is not None and capacity < size):
        return -2, b""
    return size, b"".join(x.to_bytes(8, "little", signed=True) for x in answers)
