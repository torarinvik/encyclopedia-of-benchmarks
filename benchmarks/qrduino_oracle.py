"""Oracle for the bounded clean-room Embench-IoT QR encoder profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MESSAGE_LENGTH = 21
MATRIX_WIDTH = 25
MATRIX_CELLS = MATRIX_WIDTH * MATRIX_WIDTH
DATA_CODEWORDS = 34
ECC_CODEWORDS = 10
OUTPUT_BYTES = 22
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _gf_multiply(left: int, right: int) -> int:
    product = 0
    while right:
        if right & 1:
            product ^= left
        right >>= 1
        left <<= 1
        if left & 0x100:
            left ^= 0x11D
    return product


def _put_bits(target: list[int], position: int, value: int, width: int) -> int:
    for shift in range(width - 1, -1, -1):
        if (value >> shift) & 1:
            target[position >> 3] |= 0x80 >> (position & 7)
        position += 1
    return position


def _codewords(message: Sequence[int]) -> list[int]:
    data = [0] * DATA_CODEWORDS
    bit_position = 0
    bit_position = _put_bits(data, bit_position, 4, 4)
    bit_position = _put_bits(data, bit_position, len(message), 8)
    for byte in message:
        bit_position = _put_bits(data, bit_position, byte, 8)
    bit_position = _put_bits(data, bit_position, 0, min(4, DATA_CODEWORDS * 8 - bit_position))
    while bit_position & 7:
        bit_position = _put_bits(data, bit_position, 0, 1)

    next_pad = 0xEC
    while bit_position < DATA_CODEWORDS * 8:
        bit_position = _put_bits(data, bit_position, next_pad, 8)
        next_pad = 0x11 if next_pad == 0xEC else 0xEC

    generator = [0] * (ECC_CODEWORDS + 1)
    generator[0] = 1
    degree = 0
    root = 1
    for _ in range(ECC_CODEWORDS):
        generator[degree + 1] = 1
        for index in range(degree, 0, -1):
            prior = generator[index - 1]
            current = generator[index]
            generator[index] = prior ^ _gf_multiply(current, root) if current else prior
        generator[0] = _gf_multiply(generator[0], root)
        degree += 1
        root = _gf_multiply(root, 2)

    ecc = [0] * ECC_CODEWORDS
    for byte in data:
        factor = byte ^ ecc[0]
        for index in range(ECC_CODEWORDS - 1):
            ecc[index] = ecc[index + 1] ^ _gf_multiply(factor, generator[index + 1])
        ecc[-1] = _gf_multiply(factor, generator[0])
    return data + ecc


def _mark(matrix: list[int], reserved: list[bool], x: int, y: int, dark: bool) -> None:
    if 0 <= x < MATRIX_WIDTH and 0 <= y < MATRIX_WIDTH:
        index = y * MATRIX_WIDTH + x
        reserved[index] = True
        if dark:
            matrix[index] = 1


def _finder(matrix: list[int], reserved: list[bool], left: int, top: int) -> None:
    _mark(matrix, reserved, left + 3, top + 3, True)
    for offset in range(6):
        _mark(matrix, reserved, left + offset, top, True)
        _mark(matrix, reserved, left, top + offset + 1, True)
        _mark(matrix, reserved, left + 6, top + offset, True)
        _mark(matrix, reserved, left + offset + 1, top + 6, True)
    for offset in range(1, 5):
        _mark(matrix, reserved, left + offset, top + 1, False)
        _mark(matrix, reserved, left + 1, top + offset + 1, False)
        _mark(matrix, reserved, left + 5, top + offset, False)
        _mark(matrix, reserved, left + offset + 1, top + 5, False)
    for offset in range(2, 4):
        _mark(matrix, reserved, left + offset, top + 2, True)
        _mark(matrix, reserved, left + 2, top + offset + 1, True)
        _mark(matrix, reserved, left + 4, top + offset, True)
        _mark(matrix, reserved, left + offset + 1, top + 4, True)


def _alignment(matrix: list[int], reserved: list[bool], center_x: int, center_y: int) -> None:
    _mark(matrix, reserved, center_x, center_y, True)
    for offset in range(-2, 2):
        _mark(matrix, reserved, center_x + offset, center_y - 2, True)
        _mark(matrix, reserved, center_x - 2, center_y + offset + 1, True)
        _mark(matrix, reserved, center_x + 2, center_y + offset, True)
        _mark(matrix, reserved, center_x + offset + 1, center_y + 2, True)
    for offset in range(2):
        _mark(matrix, reserved, center_x - 1, center_y + offset, False)
        _mark(matrix, reserved, center_x + 1, center_y - offset, False)
        _mark(matrix, reserved, center_x - offset, center_y - 1, False)
        _mark(matrix, reserved, center_x + offset, center_y + 1, False)


def _base_frame() -> tuple[list[int], list[bool]]:
    matrix = [0] * MATRIX_CELLS
    reserved = [False] * MATRIX_CELLS
    _finder(matrix, reserved, 0, 0)
    _finder(matrix, reserved, MATRIX_WIDTH - 7, 0)
    _finder(matrix, reserved, 0, MATRIX_WIDTH - 7)
    _alignment(matrix, reserved, 18, 18)

    _mark(matrix, reserved, 8, MATRIX_WIDTH - 8, True)
    for coordinate in range(9):
        _mark(matrix, reserved, coordinate, 8, False)
    for coordinate in range(8):
        _mark(matrix, reserved, coordinate + MATRIX_WIDTH - 8, 8, False)
        _mark(matrix, reserved, 8, coordinate, False)
    for coordinate in range(7):
        _mark(matrix, reserved, 8, coordinate + MATRIX_WIDTH - 7, False)

    for coordinate in range(MATRIX_WIDTH - 14):
        dark = (coordinate & 1) == 0
        _mark(matrix, reserved, 8 + coordinate, 6, dark)
        _mark(matrix, reserved, 6, 8 + coordinate, dark)

    # Existing black function modules are unavailable to data placement too.
    for y in range(MATRIX_WIDTH):
        for x in range(y + 1):
            index = y * MATRIX_WIDTH + x
            if matrix[index]:
                reserved[index] = True
    return matrix, reserved


def _place_data(matrix: list[int], reserved: list[bool], words: Sequence[int]) -> None:
    x = MATRIX_WIDTH - 1
    y = MATRIX_WIDTH - 1
    moving_up = True
    moving_left = True
    for word in words:
        byte = word
        for _ in range(8):
            if byte & 0x80:
                matrix[y * MATRIX_WIDTH + x] = 1
            byte = (byte << 1) & 0xFF
            while True:
                if moving_left:
                    x -= 1
                else:
                    x += 1
                    if moving_up:
                        if y != 0:
                            y -= 1
                        else:
                            x -= 2
                            moving_up = False
                            if x == 6:
                                x -= 1
                                y = 9
                    elif y != MATRIX_WIDTH - 1:
                        y += 1
                    else:
                        x -= 2
                        moving_up = True
                        if x == 6:
                            x -= 1
                            y -= 8
                moving_left = not moving_left
                if not reserved[y * MATRIX_WIDTH + x]:
                    break


def _masked(matrix: Sequence[int], reserved: Sequence[bool], mask: int) -> list[int]:
    candidate = list(matrix)
    for y in range(MATRIX_WIDTH):
        for x in range(MATRIX_WIDTH):
            index = y * MATRIX_WIDTH + x
            if reserved[index]:
                continue
            if (
                (mask == 0 and (x + y) % 2 == 0)
                or (mask == 1 and y % 2 == 0)
                or (mask == 2 and x % 3 == 0)
                or (mask == 3 and (x + y) % 3 == 0)
                or (mask == 4 and (y // 2 + x // 3) % 2 == 0)
                or (mask == 5 and x * y % 2 + x * y % 3 == 0)
                or (mask == 6 and (x * y % 2 + x * y % 3) % 2 == 0)
                or (mask == 7 and ((x + y) % 2 + x * y % 3) % 2 == 0)
            ):
                candidate[index] ^= 1
    data = 8 | mask
    remainder = data << 10
    for bit in range(14, 9, -1):
        if remainder & (1 << bit):
            remainder ^= 0x537 << (bit - 10)
    format_word = ((data << 10) | remainder) ^ 0x5412
    for bit in range(6):
        candidate[bit * MATRIX_WIDTH + 8] = (format_word >> bit) & 1
    candidate[7 * MATRIX_WIDTH + 8] = (format_word >> 6) & 1
    candidate[8 * MATRIX_WIDTH + 8] = (format_word >> 7) & 1
    candidate[8 * MATRIX_WIDTH + 7] = (format_word >> 8) & 1
    for bit in range(9, 15):
        candidate[8 * MATRIX_WIDTH + 14 - bit] = (format_word >> bit) & 1
    for bit in range(8):
        candidate[8 * MATRIX_WIDTH + MATRIX_WIDTH - 1 - bit] = (format_word >> bit) & 1
    for bit in range(8, 15):
        candidate[(MATRIX_WIDTH - 15 + bit) * MATRIX_WIDTH + 8] = (format_word >> bit) & 1
    candidate[(MATRIX_WIDTH - 8) * MATRIX_WIDTH + 8] = 1
    return candidate


def _penalty(matrix: Sequence[int]) -> int:
    score = 0
    for is_row in (True, False):
        for line in range(MATRIX_WIDTH):
            values = [
                matrix[line * MATRIX_WIDTH + step]
                if is_row
                else matrix[step * MATRIX_WIDTH + line]
                for step in range(MATRIX_WIDTH)
            ]
            run = 1
            for step in range(1, MATRIX_WIDTH):
                if values[step] == values[step - 1]:
                    run += 1
                else:
                    if run >= 5:
                        score += run - 2
                    run = 1
            if run >= 5:
                score += run - 2
            for start in range(MATRIX_WIDTH - 10):
                pattern = values[start : start + 11]
                if pattern in (
                    [0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1],
                    [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0],
                ):
                    score += 40
    for y in range(MATRIX_WIDTH - 1):
        for x in range(MATRIX_WIDTH - 1):
            a = matrix[y * MATRIX_WIDTH + x]
            if (
                a == matrix[y * MATRIX_WIDTH + x + 1]
                and a == matrix[(y + 1) * MATRIX_WIDTH + x]
                and a == matrix[(y + 1) * MATRIX_WIDTH + x + 1]
            ):
                score += 3
    dark = sum(matrix)
    score += abs(dark * 20 - MATRIX_CELLS * 10) // MATRIX_CELLS * 10
    return score


def _encoded_prefix(message: Sequence[int]) -> bytes:
    matrix, reserved = _base_frame()
    _place_data(matrix, reserved, _codewords(message))
    # QRduino snapshots strinbuf immediately after unmasked frame placement.
    prefix = bytearray()
    for y in range(6):
        for x_byte in range(4 if y < 5 else 2):
            packed = 0
            for bit in range(8):
                x = x_byte * 8 + bit
                if x < MATRIX_WIDTH and matrix[y * MATRIX_WIDTH + x]:
                    packed |= 0x80 >> bit
            prefix.append(packed)
    # Run the eight format/mask candidate evaluations from the encoder profile.
    _ = min(_penalty(_masked(matrix, reserved, mask)) for mask in range(8))
    return bytes(prefix)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the 22-byte source-verification snapshot of a version-2-L QR frame."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0))
        or (input_length is not None and (type(input_length) is not int or input_length < 0))
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if (
        not 2 <= len(values) <= MAX_MESSAGE_LENGTH + 2
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""
    length = values[0]
    if not 1 <= length <= MAX_MESSAGE_LENGTH or len(values) != length + 1:
        return INVALID_RESULT, b""
    message = values[1:]
    if any(not 1 <= byte <= 127 for byte in message):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    output = _encoded_prefix(message)
    return len(output), output
