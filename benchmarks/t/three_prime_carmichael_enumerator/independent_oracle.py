"""Korselt-criterion verifier for parameter-generated prime triples."""

from __future__ import annotations

import struct
from math import isqrt

from .primary_oracle import (
    MAX_LIMIT,
    MAX_PARSEABLE_INPUT_LENGTH,
    _is_prime,
)


def _is_carmichael_triple(p1: int, p2: int, p3: int) -> bool:
    if not (p1 < p2 < p3 and _is_prime(p1) and _is_prime(p2) and _is_prime(p3)):
        return False
    product_minus_one = p1 * p2 * p3 - 1
    return all(product_minus_one % (prime - 1) == 0 for prime in (p1, p2, p3))


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None) -> bytes | int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) != 1 or not 2 <= values[0] <= MAX_LIMIT:
        return -1

    # Enumerate p1 and p2, then use Korselt's p3-1 divisor condition. This
    # independent search does not use the primary h3,d candidate loops.
    limit = values[0]
    keyed_triples: list[tuple[int, int, int, int, int]] = []
    for p1 in range(2, limit + 1):
        if not _is_prime(p1):
            continue
        p2_bound = 1 + (p1 - 1) * (2 * p1 - 1)
        for p2 in range(p1 + 1, p2_bound + 1):
            if not _is_prime(p2):
                continue
            target = p1 * p2 - 1
            for divisor in range(1, isqrt(target) + 1):
                if target % divisor != 0:
                    continue
                factors = ((divisor,) if divisor * divisor == target
                           else (divisor, target // divisor))
                for factor in factors:
                    p3 = factor + 1
                    if p3 <= p2 or not _is_carmichael_triple(p1, p2, p3):
                        continue
                    for h3 in range(2, p1):
                        if 1 + (p1 * p2) // h3 != p3:
                            continue
                        numerator = (h3 + p1) * (p1 - 1)
                        p2_minus_one = p2 - 1
                        if numerator % p2_minus_one != 0:
                            continue
                        d = numerator // p2_minus_one
                        if not 1 <= d < h3 + p1:
                            continue
                        if (-p1 * p1) % h3 != d % h3:
                            continue
                        keyed_triples.append((p1, h3, d, p2, p3))

    keyed_triples.sort()
    triples = [(p1, p2, p3) for p1, _h3, _d, p2, p3 in keyed_triples]
    encoded = bytearray(struct.pack("<I", len(triples)))
    for triple in triples:
        encoded.extend(struct.pack("<III", *triple))
    return bytes(encoded)
