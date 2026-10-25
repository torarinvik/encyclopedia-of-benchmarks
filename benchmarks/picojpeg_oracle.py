"""Independent model for the bounded single-block baseline JPEG profile."""
from collections.abc import Sequence

MAX_INPUT_LENGTH = 139
MAX_OUTPUT_BYTES = 64
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_IDCT_Q16 = (11363, 9633, 6436, 2260, -2260, -6436, -9633, -11363)


def _header() -> list[int]:
    values = [0xFF, 0xD8, 0xFF, 0xDB, 0, 0x43, 0]
    values.extend([1] * 64)
    values.extend((
        0xFF, 0xC0, 0, 0x0B, 8, 0, 8, 0, 8, 1, 1, 0x11, 0,
        0xFF, 0xC4, 0, 0x27, 0,
        1, *([0] * 15), 4,
        0x10, 1, 1, *([0] * 14), 4, 0,
        0xFF, 0xDA, 0, 8, 1, 1, 0, 0, 0x3F, 0,
    ))
    return values


def _bits_to_coefficient(bits: str, offset: int) -> tuple[int, int]:
    if bits[offset] != "0":
        raise ValueError("unexpected Huffman code")
    raw = int(bits[offset + 1:offset + 5], 2)
    return (raw if raw >= 8 else raw - 15), offset + 5


def expected_output(values: Sequence[int]) -> bytes | None:
    if (not isinstance(values, Sequence) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= 255 for value in values)):
        return None
    prefix = _header()
    for index, expected in enumerate(prefix):
        if index in (7, 8):
            if not 1 <= values[index] <= 255:
                return None
        elif values[index] != expected:
            return None
    if values[137:139] != [0xFF, 0xD9]:
        return None
    scan_bits = "".join(f"{byte:08b}" for byte in values[135:137])
    try:
        dc, offset = _bits_to_coefficient(scan_bits, 0)
        ac, offset = _bits_to_coefficient(scan_bits, offset)
    except (ValueError, IndexError):
        return None
    if scan_bits[offset:offset + 2] != "10" or scan_bits[offset + 2:] != "1111":
        return None
    dc *= values[7]
    ac *= values[8]
    output = bytearray()
    for _row in range(8):
        for factor in _IDCT_Q16:
            numerator = 128 * 65536 + dc * 8192 + ac * factor
            output.append(max(0, min(255, (numerator + 32768) // 65536)))
    return bytes(output)


def expected_result(values: Sequence[int], output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (input_is_null or type(output_is_null) is not bool
            or not isinstance(values, Sequence)
            or type(output_capacity) is not int or output_capacity < 0
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return INVALID_RESULT
    output = expected_output(values)
    if output is None:
        return INVALID_RESULT
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR
    return len(output)
