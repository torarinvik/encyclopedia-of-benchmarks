"""Trial-factor and list-recomputation reference for EKG terms."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_CANDIDATE = 40_320
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    supplied_length = len(values) if input_length is None else input_length
    if (type(supplied_length) is not int or supplied_length != len(values)
            or supplied_length != 1):
        return None
    requested = values[0]
    return requested if 1 <= requested <= MAX_N else None


def _has_common_factor_by_trial_division(left: int, right: int) -> bool:
    factor = 2
    while factor * factor <= left:
        if left % factor == 0 and right % factor == 0:
            return True
        factor += 1
    return left > 1 and right % left == 0


def _construct_by_recomputation(count: int) -> list[int]:
    terms = [1]
    if count == 1:
        return terms
    terms.append(2)
    while len(terms) < count:
        position = len(terms) + 1
        bound = terms[-1] * position
        for candidate in range(1, min(bound, MAX_CANDIDATE) + 1):
            if candidate not in terms and _has_common_factor_by_trial_division(
                    terms[-1], candidate):
                terms.append(candidate)
                break
        else:
            return []
    return terms


def _serialize_by_shifts(terms: Sequence[int]) -> bytes:
    output = bytearray()
    for term in terms:
        for byte_index in range(8):
            output.append((term >> (8 * byte_index)) & 0xFF)
    return bytes(output)


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    requested = _parse(values, input_is_null, input_length)
    if requested is None:
        return INVALID_RESULT, b""
    terms = _construct_by_recomputation(requested)
    if not terms:
        return INVALID_RESULT, b""
    encoded = _serialize_by_shifts(terms)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int
                     or output_capacity < len(encoded)))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
