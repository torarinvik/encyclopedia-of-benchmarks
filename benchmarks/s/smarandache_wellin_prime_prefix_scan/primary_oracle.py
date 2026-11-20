"""Streaming Smarandache-Wellin prime-prefix scan with deterministic MR."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 6
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 24
WORKSPACE_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1
_SMALL_PRIMES = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
_MR_BASES = (2, 7, 61)


def _small_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    for prime in _SMALL_PRIMES:
        if value == prime:
            return True
        if value % prime == 0:
            return False

    odd_part = value - 1
    twos = 0
    while odd_part % 2 == 0:
        odd_part //= 2
        twos += 1

    for base in _MR_BASES:
        witness = pow(base, odd_part, value)
        if witness == 1 or witness == value - 1:
            continue
        for _ in range(twos - 1):
            witness = (witness * witness) % value
            if witness == value - 1:
                break
        else:
            return False
    return True


def _prefix_primes(count: int) -> tuple[int, ...]:
    result: list[int] = []
    candidate = 2
    prefix = 0
    for _ in range(count):
        while not _small_prime(candidate):
            candidate += 1 if candidate == 2 else 2
        digits = len(str(candidate))
        prefix = prefix * (10 ** digits) + candidate
        if _is_prime(prefix):
            result.append(prefix)
        candidate += 1 if candidate == 2 else 2
    return tuple(result)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not 0 <= values[0] <= MAX_COUNT:
        return None
    return values[0]


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
    count = _parse(values, input_is_null, input_length)
    if count is None:
        return INVALID_RESULT, b""
    staged = b"".join(value.to_bytes(8, "little", signed=True)
                      for value in _prefix_primes(count))
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
