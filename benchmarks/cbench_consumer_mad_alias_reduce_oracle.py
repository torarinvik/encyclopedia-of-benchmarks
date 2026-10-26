"""Independent integer oracle for the bounded libmad alias-reduction profile."""

from __future__ import annotations

from collections.abc import Sequence

CS = (0x0DB84A81, 0x0E1B9D7F, 0x0F31ADCF, 0x0FBBA815,
      0x0FEDA417, 0x0FFC8FC8, 0x0FFF964C, 0x0FFFF8D3)
CA = (-0x083B5FE7, -0x078C36D2, -0x05039814, -0x02E91DD1,
      -0x0183603A, -0x00A7CB87, -0x003A2847, -0x000F27B4)
MAX_BOUNDARIES = 4
MAX_INPUT_LENGTH = 65
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 256
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _mad_mul(left: int, right: int) -> int:
    """Model FPM_DEFAULT's two biased shifts and subsequent integer product."""
    return ((left + 2048) // 4096) * ((right + 32768) // 65536)


def _valid(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> bool:
    if input_is_null or not isinstance(values, (list, tuple)):
        return False
    if len(values) < 1 or len(values) > MAX_INPUT_LENGTH:
        return False
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return False
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return False
    boundaries = values[0]
    if not 1 <= boundaries <= MAX_BOUNDARIES or len(values) != 1 + 16 * boundaries:
        return False
    return all(-100_000_000 <= value <= 100_000_000 for value in values[1:])


def calculate(values: Sequence[int]) -> bytes:
    """Transform each adjacent subband-boundary pair, then encode Q28 i32s."""
    transformed: list[int] = []
    boundaries = values[0]
    for boundary in range(boundaries):
        base = 1 + 16 * boundary
        for pair in range(8):
            a = values[base + 2 * pair]
            b = values[base + 2 * pair + 1]
            transformed.append(_mad_mul(a, CS[pair]) + _mad_mul(-b, CA[pair]))
            transformed.append(_mad_mul(b, CS[pair]) + _mad_mul(a, CA[pair]))
    return b"".join(value.to_bytes(4, byteorder="little", signed=True) for value in transformed)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID_RESULT, b""
    if not _valid(values, input_is_null, input_length):
        return INVALID_RESULT, b""
    required = 64 * values[0]
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""
    return required, calculate(values)
