"""Exact integer oracle for the bounded Gaussian-integer GCD workload."""

MAX_T = 8
MAX_COMPONENT = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 1 + 4 * MAX_T
MAX_OUTPUT_BYTES = 8 * MAX_T


def _nearest_quotient(numerator, denominator):
    """Round an exact ratio to nearest, resolving ties away from zero."""
    magnitude, remainder = divmod(abs(numerator), denominator)
    if 2 * remainder >= denominator:
        magnitude += 1
    return -magnitude if numerator < 0 else magnitude


def _canonical_gcd(ar, ai, br, bi):
    while br != 0 or bi != 0:
        denominator = br * br + bi * bi
        quotient_real = _nearest_quotient(ar * br + ai * bi, denominator)
        quotient_imag = _nearest_quotient(ai * br - ar * bi, denominator)
        remainder_real = ar - (quotient_real * br - quotient_imag * bi)
        remainder_imag = ai - (quotient_real * bi + quotient_imag * br)
        ar, ai, br, bi = br, bi, remainder_real, remainder_imag

    if ar == 0 and ai == 0:
        return 0, 0
    for _ in range(4):
        if ar > 0 and ai >= 0:
            return ar, ai
        ar, ai = -ai, ar
    raise AssertionError("a nonzero Gaussian integer must have a canonical associate")


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for packed ``[T,(ar,ai,br,bi)...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or not values):
        return -1, b""
    test_count = values[0]
    if type(test_count) is not int or not 1 <= test_count <= MAX_T:
        return -1, b""
    if len(values) != 1 + 4 * test_count:
        return -1, b""
    components = values[1:]
    if any(type(value) is not int or not -MAX_COMPONENT <= value <= MAX_COMPONENT
           for value in components):
        return -1, b""

    required = 8 * test_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""

    output = bytearray()
    for offset in range(0, len(components), 4):
        ar, ai, br, bi = components[offset:offset + 4]
        real, imaginary = _canonical_gcd(ar, ai, br, bi)
        output.extend(real.to_bytes(4, "little"))
        output.extend(imaginary.to_bytes(4, "little"))
    result = bytes(output)
    return len(result), result
