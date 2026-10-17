"""Independent oracle for the bounded raw-byte MD2 digest benchmark."""

from __future__ import annotations

import math


MAX_INPUT_LENGTH = 63
MAX_BYTE_VALUE = 255
OUTPUT_LENGTH = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_S = (
    41, 46, 67, 201, 162, 216, 124, 1, 61, 54, 84, 161, 236, 240, 6, 19,
    98, 167, 5, 243, 192, 199, 115, 140, 152, 147, 43, 217, 188, 76, 130, 202,
    30, 155, 87, 60, 253, 212, 224, 22, 103, 66, 111, 24, 138, 23, 229, 18,
    190, 78, 196, 214, 218, 158, 222, 73, 160, 251, 245, 142, 187, 47, 238, 122,
    169, 104, 121, 145, 21, 178, 7, 63, 148, 194, 16, 137, 11, 34, 95, 33,
    128, 127, 93, 154, 90, 144, 50, 39, 53, 62, 204, 231, 191, 247, 151, 3,
    255, 25, 48, 179, 72, 165, 181, 209, 215, 94, 146, 42, 172, 86, 170, 198,
    79, 184, 56, 210, 150, 164, 125, 182, 118, 252, 107, 226, 156, 116, 4, 241,
    69, 157, 112, 89, 100, 113, 135, 32, 134, 91, 207, 101, 230, 45, 168, 2,
    27, 96, 37, 173, 174, 176, 185, 246, 28, 70, 97, 105, 52, 64, 126, 15,
    85, 71, 163, 35, 221, 81, 175, 58, 195, 92, 249, 206, 186, 197, 234, 38,
    44, 83, 13, 110, 133, 40, 132, 9, 211, 223, 205, 244, 65, 129, 77, 82,
    106, 220, 55, 200, 108, 193, 171, 250, 36, 225, 123, 8, 12, 189, 177, 74,
    120, 136, 149, 139, 227, 99, 232, 109, 233, 203, 213, 254, 59, 0, 29, 57,
    242, 239, 183, 14, 102, 88, 208, 228, 166, 119, 114, 248, 235, 117, 75, 10,
    49, 68, 80, 180, 143, 237, 31, 26, 219, 153, 141, 51, 159, 17, 131, 20,
)


def _digest(message: bytes) -> bytes:
    """Compute MD2 with the RFC 1319 padding, checksum, and block transform."""
    padding_length = 16 - (len(message) % 16)
    padded = message + bytes((padding_length,)) * padding_length

    checksum = bytearray(16)
    last = 0
    for block_start in range(0, len(padded), 16):
        block = padded[block_start:block_start + 16]
        for index, value in enumerate(block):
            checksum[index] ^= _S[value ^ last]
            last = checksum[index]

    state = bytearray(48)
    for block_start in range(0, len(padded) + 16, 16):
        block = (padded + checksum)[block_start:block_start + 16]
        for index, value in enumerate(block):
            state[index + 16] = value
            state[index + 32] = value ^ state[index]

        temporary = 0
        for round_index in range(18):
            for index in range(48):
                state[index] ^= _S[temporary]
                temporary = state[index]
            temporary = (temporary + round_index) & 0xFF

    return bytes(state[:OUTPUT_LENGTH])


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    """Return the exact digest octets, or ``None`` for an invalid ABI input."""
    if not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH:
        return None

    message = bytearray()
    for value in values:
        if type(value) not in (int, float):
            return None
        number = float(value)
        if (not math.isfinite(number) or number != math.floor(number)
                or not 0 <= number <= MAX_BYTE_VALUE):
            return None
        message.append(int(number))

    return [float(value) for value in _digest(bytes(message))]
