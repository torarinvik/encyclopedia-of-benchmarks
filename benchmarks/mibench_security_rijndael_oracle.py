"""Independent algebraic oracle for the bounded MiBench Rijndael kernel."""

from __future__ import annotations

from collections.abc import Sequence

KEY_BYTES = 32
BLOCK_BYTES = 16
INPUT_BYTES = KEY_BYTES + BLOCK_BYTES
OUTPUT_BYTES = BLOCK_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _gf_multiply(left: int, right: int) -> int:
    product = 0
    while right:
        if right & 1:
            product ^= left
        left = ((left << 1) ^ (0x11B if left & 0x80 else 0)) & 0xFF
        right >>= 1
    return product


def _substitution_table() -> tuple[int, ...]:
    table = []
    for value in range(256):
        inverse = 0
        if value:
            power, exponent = value, 254
            inverse = 1
            while exponent:
                if exponent & 1:
                    inverse = _gf_multiply(inverse, power)
                power = _gf_multiply(power, power)
                exponent >>= 1
        rotated1 = ((inverse << 1) | (inverse >> 7)) & 0xFF
        rotated2 = ((inverse << 2) | (inverse >> 6)) & 0xFF
        rotated3 = ((inverse << 3) | (inverse >> 5)) & 0xFF
        rotated4 = ((inverse << 4) | (inverse >> 4)) & 0xFF
        table.append(inverse ^ rotated1 ^ rotated2 ^ rotated3 ^ rotated4 ^ 0x63)
    return tuple(table)


def _expand_key(key: Sequence[int], sbox: Sequence[int]) -> list[int]:
    expanded = list(key)
    round_constant = 1
    while len(expanded) < 240:
        word_index = len(expanded) // 4
        temporary = expanded[-4:]
        if word_index % 8 == 0:
            temporary = temporary[1:] + temporary[:1]
            temporary = [sbox[byte] for byte in temporary]
            temporary[0] ^= round_constant
            round_constant = ((round_constant << 1) ^ (0x11B if round_constant & 0x80 else 0)) & 0xFF
        elif word_index % 8 == 4:
            temporary = [sbox[byte] for byte in temporary]
        for index in range(4):
            expanded.append(expanded[-32] ^ temporary[index])
    return expanded


def _encrypt_block(key: Sequence[int], block: Sequence[int]) -> bytes:
    sbox = _substitution_table()
    round_keys = _expand_key(key, sbox)
    state = list(block)

    def add_round_key(round_index: int) -> None:
        offset = round_index * 16
        for index in range(16):
            state[index] ^= round_keys[offset + index]

    def sub_bytes() -> None:
        for index in range(16):
            state[index] = sbox[state[index]]

    def shift_rows() -> None:
        previous = state.copy()
        for column in range(4):
            for row in range(4):
                state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)]

    def xtime(value: int) -> int:
        return ((value << 1) ^ (0x1B if value & 0x80 else 0)) & 0xFF

    def mix_columns() -> None:
        for column in range(4):
            offset = 4 * column
            a0, a1, a2, a3 = state[offset:offset + 4]
            total = a0 ^ a1 ^ a2 ^ a3
            state[offset] = a0 ^ total ^ xtime(a0 ^ a1)
            state[offset + 1] = a1 ^ total ^ xtime(a1 ^ a2)
            state[offset + 2] = a2 ^ total ^ xtime(a2 ^ a3)
            state[offset + 3] = a3 ^ total ^ xtime(a3 ^ a0)

    add_round_key(0)
    for round_index in range(1, 14):
        sub_bytes()
        shift_rows()
        mix_columns()
        add_round_key(round_index)
    sub_bytes()
    shift_rows()
    add_round_key(14)
    return bytes(state)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return AES-256 encryption of one block or the documented ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    if (len(values) != INPUT_BYTES
            or any(type(value) is not int or not 0 <= value <= 255 for value in values)):
        return INVALID_RESULT, b""
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, _encrypt_block(values[:KEY_BYTES], values[KEY_BYTES:])
