"""Independent oracle for the bounded proof-of-work benchmark."""

from __future__ import annotations

from collections.abc import Sequence
import hashlib
import struct

MIN_DIFFICULTY = 0
MAX_DIFFICULTY = 8
MIN_NONCE = 0
MAX_NONCE = 65_535
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 40
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
PREIMAGE_PREFIX = b"00Genesis Block0.0"


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return `(written_bytes_or_error, bytes)` for one bounded search."""
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT, b""

    if len(values) != MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT, b""
    difficulty, max_nonce = values
    if not MIN_DIFFICULTY <= difficulty <= MAX_DIFFICULTY:
        return INVALID_RESULT, b""
    if not MIN_NONCE <= max_nonce <= MAX_NONCE:
        return INVALID_RESULT, b""

    target = "0" * difficulty
    for nonce in range(max_nonce + 1):
        preimage = PREIMAGE_PREFIX + str(nonce).encode("ascii")
        digest = hashlib.sha256(preimage).digest()
        if digest.hex().startswith(target):
            if output_is_null or (
                capacity is not None
                and (type(capacity) is not int or capacity < MAX_OUTPUT_BYTES)
            ):
                return OUTPUT_ERROR, b""
            return MAX_OUTPUT_BYTES, struct.pack("<q", nonce) + digest
    return 0, b""


def expected_result(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    return expected_output(values, capacity, output_is_null)
