"""Prime-implicant and dynamic-programming oracle for exact QM minimization."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARIABLES = 3
MAX_INPUT = 1 + (1 << MAX_VARIABLES)
MAX_OUTPUT_BYTES = 8 * (1 + 2 * (1 << MAX_VARIABLES))
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _valid_cube(care: int, value: int, statuses: Sequence[int], size: int) -> tuple[bool, int]:
    cover = 0
    for minterm in range(size):
        if minterm & care == value:
            if statuses[minterm] == 0:
                return False, 0
            if statuses[minterm] == 1:
                cover |= 1 << minterm
    return cover != 0, cover


def _prime_implicants(statuses: list[int], n: int) -> list[tuple[int, int, int, int]]:
    size = 1 << n
    full = size - 1
    result = []
    for care in range(full + 1):
        for value in range(full + 1):
            if value & ~care:
                continue
            valid, cover = _valid_cube(care, value, statuses, size)
            if not valid:
                continue
            prime = True
            for variable in range(n):
                bit = 1 << variable
                if care & bit and _valid_cube(care ^ bit, value & ~bit, statuses, size)[0]:
                    prime = False
                    break
            if prime:
                result.append((care, value, cover, care.bit_count()))
    return result


def _lexicographically_better(candidate: int, incumbent: int, count: int) -> bool:
    for index in range(count):
        left = bool(candidate & (1 << index))
        right = bool(incumbent & (1 << index))
        if left != right:
            return left
    return False


def _minimum_cover(statuses: list[int], n: int) -> list[tuple[int, int]]:
    on_mask = sum((1 << index) for index, status in enumerate(statuses) if status == 1)
    if on_mask == 0:
        return []
    primes = _prime_implicants(statuses, n)
    state_count = 1 << len(statuses)
    infinity = 99
    terms = [infinity] * state_count
    literals = [infinity] * state_count
    selected = [0] * state_count
    terms[0] = 0
    literals[0] = 0
    for index, (_, _, cover, literal_count) in enumerate(primes):
        bit = 1 << index
        for covered in range(state_count - 1, -1, -1):
            if terms[covered] == infinity:
                continue
            destination = covered | cover
            if destination == covered:
                continue
            candidate_terms = terms[covered] + 1
            candidate_literals = literals[covered] + literal_count
            candidate_selected = selected[covered] | bit
            better = candidate_terms < terms[destination]
            if candidate_terms == terms[destination]:
                better = candidate_literals < literals[destination]
                if candidate_literals == literals[destination]:
                    better = _lexicographically_better(candidate_selected, selected[destination], len(primes))
            if better:
                terms[destination] = candidate_terms
                literals[destination] = candidate_literals
                selected[destination] = candidate_selected
    chosen = selected[on_mask]
    return [(care, value) for index, (care, value, _, _) in enumerate(primes)
            if chosen & (1 << index)]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        if input_is_null and values not in (None, [], ()):
            return -1, b""
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_VARIABLES or len(values) != 1 + (1 << n):
        return -1, b""
    statuses = list(values[1:])
    if any(status not in (0, 1, 2) for status in statuses):
        return -1, b""
    implicants = _minimum_cover(statuses, n)
    words = [len(implicants)]
    for care, value in implicants:
        words.extend((care, value))
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
