"""Bounded Goodstein prefixes by recursive numeric hereditary rebasing."""

from __future__ import annotations

from collections.abc import Sequence

MAX_START = 4
MAX_TRANSITIONS = 16
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 144
WORKSPACE_BYTES = 512
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _power(base: int, exponent: int) -> int:
    result = 1
    for _ in range(exponent):
        result *= base
    return result


def _rebase(value: int, base: int, raised_base: int) -> int:
    """Evaluate the hereditary base-b expansion with base symbol raised."""
    if value == 0:
        return 0
    result = 0
    place = 1
    exponent = 0
    while place <= value:
        digit = (value // place) % base
        if digit:
            raised_exponent = _rebase(exponent, base, raised_base)
            result += digit * _power(raised_base, raised_exponent)
        place *= base
        exponent += 1
    return result


def _prefix(start: int, transition_cap: int) -> tuple[int, ...]:
    terms = [start]
    current = start
    base = 2
    for _ in range(transition_cap):
        if current == 0:
            break
        current = _rebase(current, base, base + 1) - 1
        base += 1
        terms.append(current)
        if current == 0:
            break
    return tuple(terms)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    start, transition_cap = values
    if not 0 <= start <= MAX_START or not 0 <= transition_cap <= MAX_TRANSITIONS:
        return None
    return start, transition_cap


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    terms = _prefix(*parsed)
    staged = len(terms).to_bytes(8, "little", signed=True)
    staged += b"".join(term.to_bytes(8, "little", signed=True) for term in terms)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
