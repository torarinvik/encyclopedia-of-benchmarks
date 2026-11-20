"""Full-history reference for the bounded lagged subtractive sequence."""

from __future__ import annotations

MODULUS = 1_000_000_000
STATE_SIZE = 55
MAX_COUNT = 64
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 512
WORKSPACE_BYTES = 440


def _word(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def _stream(seed: int, count: int) -> list[int]:
    history = [seed, 1]
    while len(history) < STATE_SIZE:
        history.append((history[-2] - history[-1]) % MODULUS)

    first_block = [history[(34 * index) % STATE_SIZE] for index in range(1, STATE_SIZE + 1)]
    history = first_block
    target_length = 220 + count
    while len(history) < target_length:
        index = len(history)
        history.append((history[index - STATE_SIZE] - history[index - 24]) % MODULUS)
    return history[220:target_length]


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    length = len(input_values) if input_length is None else input_length
    if input_is_null or length != len(input_values) or not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if length != 2:
        return -1, b""
    seed, count = input_values
    if not 0 <= seed < MODULUS or not 0 <= count <= MAX_COUNT:
        return -1, b""
    required = count * 8
    if (required > 0 and output_is_null) or (output_capacity is not None and output_capacity < required):
        return -2, b""
    if count == 0:
        return 0, b""
    output = b"".join(_word(value) for value in _stream(seed, count))
    return len(output), output
