"""Ring-buffer reference for Bentley's bounded subtractive sequence."""

from __future__ import annotations

MODULUS = 1_000_000_000
STATE_SIZE = 55
SHORT_LAG = 24
PERMUTATION_STEP = 34
WARMUP_VALUES = 165
MAX_COUNT = 64
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 512
WORKSPACE_BYTES = 440


def _word(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def _stream(seed: int, count: int) -> list[int]:
    initial = [0] * STATE_SIZE
    initial[0] = seed
    initial[1] = 1
    for index in range(2, STATE_SIZE):
        initial[index] = (initial[index - 2] - initial[index - 1]) % MODULUS

    ring = [initial[(PERMUTATION_STEP * (index + 1)) % STATE_SIZE]
            for index in range(STATE_SIZE)]
    write_index = 0
    lag_index = STATE_SIZE - SHORT_LAG

    values: list[int] = []
    for step in range(WARMUP_VALUES + count):
        value = (ring[write_index] - ring[lag_index]) % MODULUS
        ring[write_index] = value
        if step >= WARMUP_VALUES:
            values.append(value)
        write_index = (write_index + 1) % STATE_SIZE
        lag_index = (lag_index + 1) % STATE_SIZE
    return values


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
