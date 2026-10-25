"""Independent oracle for the bounded two-pass SIC/XE assembler contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_RECORDS = 16
MAX_LABELS = 16
MAX_INPUT_LENGTH = 1 + MAX_RECORDS * 4
MODULUS = 1_000_000_007
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 9 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return INVALID_RESULT
    record_count = values[0]
    if not 2 <= record_count <= MAX_RECORDS or actual_length != 1 + 4 * record_count:
        return INVALID_RESULT

    records: list[tuple[int, int, int, int]] = []
    for index in range(record_count):
        row = tuple(values[1 + 4 * index: 5 + 4 * index])
        if len(row) != 4:
            return INVALID_RESULT
        opcode, label, kind, operand = row
        if not (0 <= opcode <= 11 and 0 <= label <= MAX_LABELS and 0 <= kind <= 5 and 0 <= operand <= 0xFFFFFF):
            return INVALID_RESULT
        records.append((opcode, label, kind, operand))

    if records[0][0] != 0 or records[-1][0] != 1 or not 1 <= records[0][1] <= MAX_LABELS:
        return INVALID_RESULT
    if records[0][2] != 0 or records[0][3] > 0xFFFFF:
        return INVALID_RESULT
    if any(opcode in (0, 1) for opcode, _, _, _ in records[1:-1]):
        return INVALID_RESULT
    if records[-1][1:] != (0, 0, 0):
        return INVALID_RESULT

    addresses = [0] * record_count
    sizes = [0] * record_count
    codes = [0] * record_count
    symbols: dict[int, int] = {}
    location = records[0][3]
    start_address = location
    addresses[0] = location
    symbols[records[0][1]] = location

    for index, (opcode, label, kind, operand) in enumerate(records):
        if index > 0:
            addresses[index] = location
            if label:
                if label in symbols or location >= 0x100000:
                    return INVALID_RESULT
                symbols[label] = location

        if opcode == 0:
            if index != 0:
                return INVALID_RESULT
            size = 0
        elif opcode == 1:
            if index != record_count - 1:
                return INVALID_RESULT
            size = 0
        elif opcode == 2:
            if kind != 0 or operand > 256:
                return INVALID_RESULT
            size = operand
        elif opcode == 3:
            if kind != 0 or operand > 256:
                return INVALID_RESULT
            size = 3 * operand
        elif opcode == 4:
            if kind != 0:
                return INVALID_RESULT
            size = 3
        elif opcode in (5, 6, 7, 8):
            if not ((kind == 1 and operand <= 4095) or
                    (kind in (2, 3) and 1 <= operand <= MAX_LABELS)):
                return INVALID_RESULT
            size = 3
        elif opcode == 9:
            if kind != 0 or operand != 0:
                return INVALID_RESULT
            size = 3
        elif opcode == 10:
            if kind != 4 or operand > 5:
                return INVALID_RESULT
            size = 2
        elif opcode == 11:
            if kind != 5 or operand >> 4 > 5 or operand & 15 > 5:
                return INVALID_RESULT
            size = 2
        else:
            return INVALID_RESULT
        sizes[index] = size
        if index > 0:
            if location > 0x100000 - size:
                return INVALID_RESULT
            location += size

    for index, (opcode, _label, kind, operand) in enumerate(records[1:-1], start=1):
        if opcode == 4:
            codes[index] = operand
        elif opcode in (5, 6, 7, 8):
            base = {5: 0x00, 6: 0x0C, 7: 0x18, 8: 0x3C}[opcode]
            ni = {1: 1, 2: 3, 3: 2}[kind]
            field = operand
            pc_relative = 0
            if kind in (2, 3):
                if operand not in symbols:
                    return INVALID_RESULT
                field = symbols[operand] - (addresses[index] + 3)
                if not -2048 <= field <= 2047:
                    return INVALID_RESULT
                pc_relative = 1
                field &= 0xFFF
            codes[index] = ((base | ni) << 16) | (pc_relative << 13) | field
        elif opcode == 9:
            codes[index] = 0x4F0000
        elif opcode == 10:
            codes[index] = 0xB400 | (operand << 4)
        elif opcode == 11:
            codes[index] = 0x9000 | operand

    checksum = ((location - start_address) * 257 + start_address * 17) % MODULUS
    for address, code, size in zip(addresses, codes, sizes, strict=True):
        checksum = (checksum * 131 + (address + 1) * 17 + code * 3 + size) % MODULUS
    return checksum
