"""Oracle for the bounded pinned Python proof-of-work routine."""

from __future__ import annotations

from collections.abc import Sequence
import hashlib

MAX_BLOCK_NUMBER = (1 << 63) - 1
MAX_DIFFICULTY = 2
MAX_NONCE = 4096
MAX_FIELD_LENGTH = 64
MIN_ASCII_CODE = 0
MAX_ASCII_CODE = 127
HEADER_LENGTH = 5
MAX_VALID_INPUT_LENGTH = HEADER_LENGTH + 2 * MAX_FIELD_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 + 64
INVALID_RESULT = -1
OUTPUT_ERROR = -2
EXHAUSTED_RESULT = -3
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return nonce and lowercase SHA-256 hex digest in the reviewed byte layout."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not HEADER_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    block_number, difficulty, max_nonce, transactions_length, previous_hash_length = values[:HEADER_LENGTH]
    if not 0 <= block_number <= MAX_BLOCK_NUMBER:
        return INVALID_RESULT, b""
    if not 0 <= difficulty <= MAX_DIFFICULTY:
        return INVALID_RESULT, b""
    if not 0 <= max_nonce <= MAX_NONCE:
        return INVALID_RESULT, b""
    if (not 0 <= transactions_length <= MAX_FIELD_LENGTH
            or not 0 <= previous_hash_length <= MAX_FIELD_LENGTH):
        return INVALID_RESULT, b""
    if len(values) != HEADER_LENGTH + transactions_length + previous_hash_length:
        return INVALID_RESULT, b""

    transactions_codes = values[HEADER_LENGTH:HEADER_LENGTH + transactions_length]
    previous_hash_codes = values[HEADER_LENGTH + transactions_length:]
    if any(not MIN_ASCII_CODE <= code <= MAX_ASCII_CODE
           for code in (*transactions_codes, *previous_hash_codes)):
        return INVALID_RESULT, b""

    if output_is_null or (
        output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES
    ):
        return OUTPUT_ERROR, b""

    transactions = "".join(chr(code) for code in transactions_codes)
    previous_hash = "".join(chr(code) for code in previous_hash_codes)
    zero_prefix = "0" * difficulty
    for nonce in range(max_nonce + 1):
        text = f"{block_number}{transactions}{previous_hash}{nonce}"
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        if digest.startswith(zero_prefix):
            encoded = nonce.to_bytes(8, byteorder="little", signed=True) + digest.encode("ascii")
            return len(encoded), encoded
    return EXHAUSTED_RESULT, b""
