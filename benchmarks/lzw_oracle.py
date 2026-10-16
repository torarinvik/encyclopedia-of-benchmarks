"""Independent oracle for the pinned Java LZW ASCII codec."""

from __future__ import annotations

MAX_ITEMS = 4096
MAX_CODES = 4351
MAX_OUTPUT = 65536
MAX_INPUT_LENGTH = MAX_ITEMS + 2
FNV_OFFSET = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
INVALID_RESULT = -1


def _fnv_i64_record(values: list[int]) -> int:
    digest = FNV_OFFSET
    for value in values:
        bits = value & MASK64
        for shift in range(0, 64, 8):
            digest = ((digest ^ ((bits >> shift) & 0xFF)) * FNV_PRIME) & MASK64
    return digest & MASK63


def _compress(data: bytes) -> list[int]:
    """The source's 256-entry byte dictionary, represented with byte strings."""
    if not data:
        return []
    dictionary = {bytes((value,)): value for value in range(256)}
    next_code = 256
    current = b""
    result: list[int] = []
    for byte in data:
        extended = current + bytes((byte,))
        if extended in dictionary:
            current = extended
        else:
            result.append(dictionary[current])
            dictionary[extended] = next_code
            next_code += 1
            current = bytes((byte,))
    result.append(dictionary[current])
    return result


def _decompress(codes: list[int]) -> bytes | None:
    """Decode valid source codes, enforcing the bounded ASCII result domain."""
    if not codes:
        return b""
    if codes[0] > 0x7F:
        return None

    dictionary = {value: bytes((value,)) for value in range(256)}
    next_code = 256
    previous = dictionary[codes[0]]
    result = bytearray(previous)
    for code in codes[1:]:
        if code in dictionary:
            entry = dictionary[code]
        elif code == next_code:
            entry = previous + previous[:1]
        else:
            return None
        if any(byte > 0x7F for byte in entry) or len(result) + len(entry) > MAX_OUTPUT:
            return None
        result.extend(entry)
        dictionary[next_code] = previous + entry[:1]
        next_code += 1
        previous = entry
    return bytes(result)


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the ABI result, or -1 when the input violates the bounded contract."""
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT

    mode, count = values[:2]
    if mode not in (0, 1) or not 0 <= count <= MAX_ITEMS or len(values) != count + 2:
        return INVALID_RESULT
    payload = list(values[2:])

    if mode == 0:
        if any(value < 0 or value > 0x7F for value in payload):
            return INVALID_RESULT
        result = _compress(bytes(payload))
    else:
        if any(value < 0 or value > MAX_CODES for value in payload):
            return INVALID_RESULT
        decoded = _decompress(payload)
        if decoded is None:
            return INVALID_RESULT
        result = list(decoded)

    return _fnv_i64_record([mode, len(result), *result])
