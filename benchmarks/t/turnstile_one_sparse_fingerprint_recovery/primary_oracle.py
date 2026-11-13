"""Replay the linear singleton-recovery counters."""

MODULUS = 1_000_000_007
MAX_INPUT_LENGTH = 260


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, q, base = values[:3]
    if not 1 <= n <= 64 or not 0 <= q <= 128 or not 1 <= base < MODULUS or len(values) != 3 + 2 * q:
        return -1
    mass = weighted = fingerprint = 0
    for offset in range(3, len(values), 2):
        index, delta = values[offset:offset + 2]
        if not 0 <= index < n or not -1000 <= delta <= 1000:
            return -1
        mass += delta
        weighted += delta * index
        fingerprint = (fingerprint + delta * pow(base, index, MODULUS)) % MODULUS
    if mass == 0 or weighted % mass != 0:
        return 0
    index = weighted // mass
    if not 0 <= index < n or fingerprint != mass * pow(base, index, MODULUS) % MODULUS:
        return 0
    return index + 1
