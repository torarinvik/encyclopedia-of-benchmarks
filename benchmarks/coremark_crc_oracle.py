"""Independent oracle for the bounded CoreMark CRC helper workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 16
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
INVALID_RESULT = -1


def _crcu8(data: int, crc: int) -> int:
    """Mirror CoreMark core_util.c's bitwise recurrence and operation order."""
    data &= 0xFF
    crc &= 0xFFFF
    for _ in range(8):
        feedback = (data & 1) ^ (crc & 1)
        data >>= 1
        if feedback:
            crc ^= 0x4002
            carry = 1
        else:
            carry = 0
        crc >>= 1
        if carry:
            crc |= 0x8000
        else:
            crc &= 0x7FFF
    return crc


def _crcu16(value: int, crc: int) -> int:
    crc = _crcu8(value & 0xFF, crc)
    return _crcu8((value >> 8) & 0xFF, crc)


def _crc16(value: int, crc: int) -> int:
    # CoreMark's signed 16-bit argument is converted back to ee_u16 before use.
    return _crcu16(value & 0xFFFF, crc)


def _crcu32(value: int, crc: int) -> int:
    crc = _crc16(value & 0xFFFF, crc)
    return _crc16((value >> 16) & 0xFFFF, crc)


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return INVALID_RESULT
    count = values[0]
    if not 1 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return INVALID_RESULT

    total = 0
    for index in range(count):
        tag, seed, value = values[1 + 3 * index:4 + 3 * index]
        if not 0 <= seed <= 0xFFFF:
            return INVALID_RESULT
        if tag == 0 and 0 <= value <= 0xFF:
            crc = _crcu8(value, seed)
        elif tag == 1 and 0 <= value <= 0xFFFF:
            crc = _crcu16(value, seed)
        elif tag == 2 and 0 <= value <= 0xFFFFFFFF:
            crc = _crcu32(value, seed)
        elif tag == 3 and -(1 << 15) <= value < (1 << 15):
            crc = _crc16(value, seed)
        else:
            return INVALID_RESULT
        total += (index + 1) * crc
    return total


oracle = expected_result
