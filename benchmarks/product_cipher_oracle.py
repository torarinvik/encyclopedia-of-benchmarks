"""Reference oracle for TheAlgorithms/Java's bounded ProductCipher transform."""

from __future__ import annotations

MAX_COLUMNS = 64
MAX_TEXT_LENGTH = 256
MAX_INPUT_VALUES = 259
MAX_OUTPUT_BYTES = 315


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (byte count or error, raw ciphertext bytes)."""
    if input_is_null:
        return -1, b""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_VALUES
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""

    columns, text_length = values[:2]
    if not 1 <= columns <= MAX_COLUMNS or not 0 <= text_length <= MAX_TEXT_LENGTH:
        return -1, b""
    if len(values) != 2 + text_length:
        return -1, b""
    text = values[2:]
    if any(byte < 0 or byte > 127 or byte in (10, 13) for byte in text):
        return -1, b""

    padded_length = 0 if text_length == 0 else (
        (text_length + columns - 1) // columns
    ) * columns
    if padded_length > MAX_OUTPUT_BYTES:
        return -1, b""
    if padded_length == 0:
        return 0, b""
    if output_is_null or (output_capacity is not None and output_capacity < padded_length):
        return -2, b""

    padded = [byte + 5 for byte in text]
    padded.extend([ord("/") for _ in range(padded_length - len(padded))])
    output = bytes(padded[column + row * columns]
                   for column in range(columns)
                   for row in range(padded_length // columns))
    return len(output), output
