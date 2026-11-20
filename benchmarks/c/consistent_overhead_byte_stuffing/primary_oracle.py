"""Streaming code-slot reference for the bounded basic COBS profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PAYLOAD = 255
MAX_VALID_INPUT_LENGTH = MAX_PAYLOAD + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 257
WORKSPACE_BYTES = 384
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> bytes | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values):
        return None
    payload_length = values[0]
    if (not 0 <= payload_length <= MAX_PAYLOAD
            or len(values) != payload_length + 1
            or any(not 0 <= value <= 255 for value in values[1:])):
        return None
    return bytes(values[1:])


def _encode_stream(payload: bytes) -> bytes:
    output = bytearray(MAX_OUTPUT_BYTES)
    written = 1
    code_position = 0
    code = 1
    omitted_terminal_code = False
    for index, byte in enumerate(payload):
        if byte == 0:
            output[code_position] = code
            code_position = written
            written += 1
            code = 1
        else:
            output[written] = byte
            written += 1
            code += 1
            if code == 255:
                output[code_position] = 255
                if index + 1 == len(payload):
                    omitted_terminal_code = True
                    break
                code_position = written
                written += 1
                code = 1
    if not omitted_terminal_code:
        output[code_position] = code
    return bytes(output[:written])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return encoded bytes and their length, or an ABI error with no bytes."""
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    payload = _parse(values, input_is_null, input_length)
    if payload is None:
        return -1, b""
    encoded = _encode_stream(payload)
    if output_is_null or capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
