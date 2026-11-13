"""Reconstruct final coordinates and compute the fingerprint from scratch."""

P = 1_000_000_007
MAX_INPUT_LENGTH = 260


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, q, base = values[:3]
    if not 1 <= n <= 64 or not 0 <= q <= 128 or not 1 <= base < P or len(values) != 3 + 2 * q:
        return -1
    vector = [0] * n
    for offset in range(3, len(values), 2):
        index, delta = values[offset:offset + 2]
        if not 0 <= index < n or not -1000 <= delta <= 1000:
            return -1
        vector[index] += delta
    mass = sum(vector)
    weighted = sum(index * value for index, value in enumerate(vector))
    if mass == 0 or weighted % mass:
        return 0
    candidate = weighted // mass
    if not 0 <= candidate < n:
        return 0
    power = 1
    fingerprint = 0
    for value in vector:
        fingerprint = (fingerprint + value * power) % P
        power = power * base % P
    return candidate + 1 if fingerprint == mass * pow(base, candidate, P) % P else 0
