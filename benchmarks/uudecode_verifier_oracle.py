"""Independent verification model for the bounded BitBench uudecode stream."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_BYTES = 4096
MAX_PARSEABLE_INPUT_VALUES = 4097
MAX_OUTPUT_BYTES = 2949
_HEADER = bytes((98, 101, 103, 105, 110, 32, 55, 53, 53, 32,
                 117, 117, 115, 116, 97, 114, 116, 46, 102, 105, 108, 101, 32, 10))
_INVALID = -1
_CAPACITY_ERROR = -2


def _decode_stream(stream: bytes) -> bytes | None:
    if len(stream) < len(_HEADER) + 5 or stream[:len(_HEADER)] != _HEADER:
        return None
    position = len(_HEADER)
    output = bytearray()
    while position < len(stream):
        line_count = stream[position]
        position += 1
        if line_count == 32:
            if stream[position:position + 2] != bytes((10,)) or stream[position + 2:] != bytes((101, 110, 100)):
                return None
            return bytes(output)
        output_count = line_count - 32
        if output_count < 1 or output_count > 45:
            return None
        encoded_size = 4 * ((output_count + 2) // 3)
        stop = position + encoded_size
        if stop >= len(stream) or stream[stop] != 10:
            return None
        symbols = stream[position:stop]
        if any(value < 32 or value > 95 for value in symbols):
            return None
        remaining = output_count
        for quartet in range(0, len(symbols), 4):
            sextets = [value - 32 for value in symbols[quartet:quartet + 4]]
            packed = (sextets[0] << 18) | (sextets[1] << 12) | (sextets[2] << 6) | sextets[3]
            output.append((packed >> 16) & 255)
            remaining -= 1
            if remaining:
                output.append((packed >> 8) & 255)
                remaining -= 1
            if remaining:
                output.append(packed & 255)
                remaining -= 1
        position = stop + 1
    return None


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return _INVALID, b""
    if (input_is_null or values is None or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or (input_length is not None and input_length != len(values))
            or len(values) > MAX_INPUT_BYTES
            or any(type(value) is not int or value < 0 or value > 255 for value in values)):
        return _INVALID, b""
    output = _decode_stream(bytes(values))
    if output is None or len(output) > MAX_OUTPUT_BYTES:
        return _INVALID, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return _CAPACITY_ERROR, b""
    return len(output), output
