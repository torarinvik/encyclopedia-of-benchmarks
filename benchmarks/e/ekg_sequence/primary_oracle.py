"""Incremental used-value and Euclidean-gcd reference for EKG terms."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_CANDIDATE = 40_320
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 8 * MAX_N
WORKSPACE_BYTES = MAX_CANDIDATE + 65
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != 1 or not 1 <= values[0] <= MAX_N):
        return None
    return values[0]


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def _construct(count: int) -> list[int] | None:
    terms = [1]
    used = bytearray(MAX_CANDIDATE + 1)
    used[1] = 1
    if count == 1:
        return terms
    terms.append(2)
    used[2] = 1
    while len(terms) < count:
        position = len(terms) + 1
        previous = terms[-1]
        search_bound = previous * position
        candidate = 1
        while candidate <= search_bound:
            if not used[candidate] and _gcd(previous, candidate) > 1:
                break
            candidate += 1
        if candidate > search_bound:
            return None
        terms.append(candidate)
        used[candidate] = 1
    return terms


def _encode(terms: Sequence[int]) -> bytes:
    return b"".join(term.to_bytes(8, "little", signed=True) for term in terms)


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return the serialized prefix or the contract's error status."""
    count = _parse(values, input_is_null, input_length)
    if count is None:
        return INVALID_RESULT, b""
    terms = _construct(count)
    if terms is None:
        return INVALID_RESULT, b""
    encoded = _encode(terms)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int
                     or output_capacity < len(encoded)))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
