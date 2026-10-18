"""Oracle for the pinned Rust SHA3-224/256/384/512 functions."""

from __future__ import annotations

import hashlib
from collections.abc import Sequence

MAX_MESSAGE_BYTES = 4096
MAX_VALID_INPUT_LENGTH = 2 + MAX_MESSAGE_BYTES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 64

INVALID_RESULT = -1
OUTPUT_ERROR = -2

HASHES = (
    hashlib.sha3_224,
    hashlib.sha3_256,
    hashlib.sha3_384,
    hashlib.sha3_512,
)


def _invalid() -> tuple[int, bytes]:
    return INVALID_RESULT, b""


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the selected SHA-3 digest or the documented ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _invalid()
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return _invalid()
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return _invalid()
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return _invalid()
    if input_length is not None and input_length != len(values):
        return _invalid()
    if (
        not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values
        )
    ):
        return _invalid()
    if len(values) < 2:
        return _invalid()

    variant, message_length = values[:2]
    if not 0 <= variant < len(HASHES):
        return _invalid()
    if not 0 <= message_length <= MAX_MESSAGE_BYTES:
        return _invalid()
    if len(values) != 2 + message_length:
        return _invalid()
    message_values = values[2:]
    if any(not 0 <= value <= 255 for value in message_values):
        return _invalid()

    digest = HASHES[variant](bytes(message_values)).digest()
    if output_is_null or (
        output_capacity is not None and output_capacity < len(digest)
    ):
        return OUTPUT_ERROR, b""
    return len(digest), digest
