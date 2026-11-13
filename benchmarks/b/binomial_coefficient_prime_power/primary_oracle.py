"""P-adic factorial-part oracle for bounded binomial coefficients mod p**e."""

from __future__ import annotations

MAX_P = 31
MAX_EXPONENT = 8
MAX_MODULUS = 1_000_000_000
MAX_QUERIES = 32
MAX_N = 128
MAX_INPUT_LENGTH = 3 + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_QUERIES
WORKSPACE_BYTES = 2560


def _prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _parse(values, input_length, input_is_null):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    prime, exponent, count = values[:3]
    if type(prime) is not int or not 2 <= prime <= MAX_P or not _prime(prime):
        return None
    if type(exponent) is not int or not 1 <= exponent <= MAX_EXPONENT:
        return None
    modulus = prime ** exponent
    if modulus > MAX_MODULUS:
        return None
    if type(count) is not int or not 0 <= count <= MAX_QUERIES:
        return None
    if len(values) != 3 + 2 * count:
        return None
    queries = []
    for index in range(count):
        n, k = values[3 + 2 * index:5 + 2 * index]
        if type(n) is not int or type(k) is not int or not 0 <= k <= n <= MAX_N:
            return None
        queries.append((n, k))
    return prime, exponent, modulus, queries


def _unit_tables(prime: int, modulus: int):
    unit_prefix = [1] * (MAX_N + 1)
    p_free_factorial = [1] * (MAX_N + 1)
    valuation = [0] * (MAX_N + 1)
    for value in range(1, MAX_N + 1):
        factor = 1 if value % prime == 0 else value
        unit_prefix[value] = unit_prefix[value - 1] * factor % modulus
        p_free_factorial[value] = (
            unit_prefix[value] * p_free_factorial[value // prime] % modulus
        )
        valuation[value] = value // prime + valuation[value // prime]
    return p_free_factorial, valuation


def _pow_mod(base: int, exponent: int, modulus: int) -> int:
    result = 1
    while exponent:
        if exponent & 1:
            result = result * base % modulus
        base = base * base % modulus
        exponent >>= 1
    return result


def _coefficient(n: int, k: int, prime: int, exponent: int, modulus: int,
                 p_free_factorial, valuation) -> int:
    power = valuation[n] - valuation[k] - valuation[n - k]
    if power >= exponent:
        return 0
    denominator = p_free_factorial[k] * p_free_factorial[n - k] % modulus
    phi = modulus // prime * (prime - 1)
    inverse = _pow_mod(denominator, phi - 1, modulus)
    prime_power = _pow_mod(prime, power, modulus)
    return p_free_factorial[n] * inverse % modulus * prime_power % modulus


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return `(output_byte_count, little-endian u32 coefficients)`."""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    prime, exponent, modulus, queries = parsed
    if type(output_is_null) is not bool:
        return -2, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -2, b""
    if not queries:
        return 0, b""
    required = 4 * len(queries)
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""

    p_free_factorial, valuation = _unit_tables(prime, modulus)
    output = bytearray()
    for n, k in queries:
        residue = _coefficient(n, k, prime, exponent, modulus,
                               p_free_factorial, valuation)
        output.extend(residue.to_bytes(4, "little"))
    return len(output), bytes(output)
