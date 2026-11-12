"""Independent bounded oracle for modular Kth-root extraction."""

from math import gcd, isqrt

MAX_T = 8
MAX_K = 1_000_000_000
MAX_P = 1_000
MAX_PARSEABLE_INPUT_LENGTH = 1 + 3 * MAX_T
MAX_OUTPUT_BYTES = 8 * MAX_T


def _is_prime(value):
    if value < 2:
        return False
    for divisor in range(2, isqrt(value) + 1):
        if value % divisor == 0:
            return False
    return True


def _distinct_prime_factors(value):
    factors = []
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            factors.append(divisor)
            while value % divisor == 0:
                value //= divisor
        divisor += 1
    if value > 1:
        factors.append(value)
    return factors


def _primitive_root(prime):
    if prime == 2:
        return 1
    order = prime - 1
    factors = _distinct_prime_factors(order)
    for candidate in range(2, prime):
        if all(pow(candidate, order // factor, prime) != 1 for factor in factors):
            return candidate
    raise AssertionError("a prime field has a primitive root")


def _root(k, y, prime):
    if k == 0:
        return 0 if y == 1 else -1
    if y == 0:
        return 0
    order = prime - 1
    generator = _primitive_root(prime)
    power = 1
    discrete_log = None
    for exponent in range(order):
        if power == y:
            discrete_log = exponent
            break
        power = power * generator % prime
    if discrete_log is None:
        return -1

    common = gcd(k, order)
    if discrete_log % common != 0:
        return -1
    reduced_order = order // common
    if reduced_order == 1:
        exponent = 0
    else:
        exponent = ((discrete_log // common)
                    * pow(k // common, -1, reduced_order)) % reduced_order
    answer = pow(generator, exponent, prime)
    return answer if pow(answer, k, prime) == y else -1


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for packed ``[T,(K,Y,P)...]``."""
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
    if len(values) != 1 + 3 * test_count:
        return -1, b""

    triples = []
    for offset in range(1, len(values), 3):
        k, y, prime = values[offset:offset + 3]
        if (type(k) is not int or not 0 <= k <= MAX_K
                or type(prime) is not int or not 2 <= prime <= MAX_P
                or type(y) is not int or not 0 <= y < prime
                or not _is_prime(prime)):
            return -1, b""
        triples.append((k, y, prime))

    required = 8 * test_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""

    output = bytearray()
    for k, y, prime in triples:
        output.extend(_root(k, y, prime).to_bytes(8, "little", signed=True))
    result = bytes(output)
    return len(result), result
