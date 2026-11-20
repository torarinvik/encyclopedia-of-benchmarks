"""Full residue-cycle oracle for primitive-root search."""

from __future__ import annotations

from .primary_oracle import I64_MAX, I64_MIN, MAX_PARSEABLE_INPUT_LENGTH, MAX_PRIME


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) != 1 or not 2 <= values[0] <= MAX_PRIME:
        return -1
    prime = values[0]
    divisor = 2
    while divisor * divisor <= prime:
        if prime % divisor == 0:
            return -1
        divisor += 1
    if prime == 2:
        return 1
    for candidate in range(2, prime):
        seen: set[int] = set()
        residue = 1
        distinct = True
        for _ in range(prime - 1):
            if residue in seen:
                distinct = False
                break
            seen.add(residue)
            residue = residue * candidate % prime
        if distinct and len(seen) == prime - 1:
            return candidate
    return -1
