"""Rolling GF(2) fingerprint oracle for bounded content-defined chunks."""

from collections.abc import Sequence

MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 64
POLYNOMIAL = 0x1100B


def _reduce(value: int) -> int:
    while value.bit_length() > 16:
        value ^= POLYNOMIAL << (value.bit_length() - 17)
    return value


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int for x in values):
        return -1, b""
    n = values[0]
    if not 0 <= n <= 64 or len(values) != n + 1 or any(not 0 <= x <= 255 for x in values[1:]):
        return -1, b""

    outgoing = [_reduce(byte << 24) for byte in range(256)]
    fingerprint = 0
    boundaries = bytearray()
    for i, byte in enumerate(values[1:]):
        fingerprint = _reduce((fingerprint << 8) | byte)
        if i >= 4:
            fingerprint ^= outgoing[values[i - 3]]
        if fingerprint & 7 == 0:
            boundaries.append(i + 1)
    if n and (not boundaries or boundaries[-1] != n):
        boundaries.append(n)
    if output_is_null or capacity is not None and capacity < len(boundaries):
        return -2, b""
    return len(boundaries), bytes(boundaries)
