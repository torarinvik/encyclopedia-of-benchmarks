"""Chunk-decomposition reference for basic COBS encoding."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PAYLOAD,
    MAX_VALID_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> bytes | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) < 1 or len(values) > MAX_VALID_INPUT_LENGTH + 1):
        return None
    count = values[0]
    if (not 0 <= count <= MAX_PAYLOAD or len(values) != count + 1
            or any(not 0 <= byte <= 255 for byte in values[1:])):
        return None
    return bytes(values[1:])


def _append_terminated_run(run: bytes, output: bytearray) -> None:
    """Encode a run whose final zero is implicit in its final ordinary code."""
    position = 0
    while len(run) - position >= 254:
        output.append(255)
        output.extend(run[position:position + 254])
        position += 254
    tail = run[position:]
    output.append(len(tail) + 1)
    output.extend(tail)


def _encode_chunks(payload: bytes) -> bytes:
    """Split at data zeroes, then encode each run as independent code blocks."""
    output = bytearray()
    run_start = 0
    for index, byte in enumerate(payload):
        if byte == 0:
            _append_terminated_run(payload[run_start:index], output)
            run_start = index + 1

    final_run = payload[run_start:]
    if final_run and len(final_run) % 254 == 0:
        for position in range(0, len(final_run), 254):
            output.append(255)
            output.extend(final_run[position:position + 254])
    else:
        # This also emits the one-byte code for empty input or a trailing zero.
        _append_terminated_run(final_run, output)
    return bytes(output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    payload = _parse(values, input_is_null, input_length)
    if payload is None:
        return -1, b""
    encoded = _encode_chunks(payload)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
