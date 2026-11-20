"""Parameterized three-prime Carmichael-number enumeration reference."""

from __future__ import annotations

import struct

MAX_LIMIT = 61
MAX_TRIPLES = 69
MAX_OUTPUT_BYTES = 4 + 12 * MAX_TRIPLES
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 4096


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not 2 <= values[0] <= MAX_LIMIT:
        return None
    return values[0]


def enumerate_triples(limit: int) -> list[tuple[int, int, int]]:
    triples: list[tuple[int, int, int]] = []
    for p1 in range(2, limit + 1):
        if not _is_prime(p1):
            continue
        for h3 in range(2, p1):
            g = h3 + p1
            for d in range(1, g):
                if (g * (p1 - 1)) % d != 0:
                    continue
                if (-p1 * p1) % h3 != d % h3:
                    continue
                p2 = 1 + (p1 - 1) * g // d
                if p2 <= p1 or not _is_prime(p2):
                    continue
                numerator = p1 * p2
                p3 = 1 + numerator // h3
                if p3 <= p2 or not _is_prime(p3):
                    continue
                if (p2 * p3) % (p1 - 1) != 1:
                    continue
                triples.append((p1, p2, p3))
    return triples


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None) -> bytes | int:
    limit = _decode(values, input_is_null, input_length)
    if limit is None:
        return -1
    triples = enumerate_triples(limit)
    encoded = bytearray(struct.pack("<I", len(triples)))
    for triple in triples:
        encoded.extend(struct.pack("<III", *triple))
    return bytes(encoded)
