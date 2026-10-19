"""Bounded independent reference for one tripforce-format DES tripcode."""

from __future__ import annotations


IP = (58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4,62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8,57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3,61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7)
IP_INV = (40,8,48,16,56,24,64,32,39,7,47,15,55,23,63,31,38,6,46,14,54,22,62,30,37,5,45,13,53,21,61,29,36,4,44,12,52,20,60,28,35,3,43,11,51,19,59,27,34,2,42,10,50,18,58,26,33,1,41,9,49,17,57,25)
E = (32,1,2,3,4,5,4,5,6,7,8,9,8,9,10,11,12,13,12,13,14,15,16,17,16,17,18,19,20,21,20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1)
P = (16,7,20,21,29,12,28,17,1,15,23,26,5,18,31,10,2,8,24,14,32,27,3,9,19,13,30,6,22,11,4,25)
PC1 = (57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,27,19,11,3,60,52,44,36,63,55,47,39,31,23,15,7,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,28,20,12,4)
PC2 = (14,17,11,24,1,5,3,28,15,6,21,10,23,19,12,4,26,8,16,7,27,20,13,2,41,52,31,37,47,55,30,40,51,45,33,48,44,49,39,56,34,53,46,42,50,36,29,32)
SHIFTS = (1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1)
SBOX = (
((14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7),(0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8),(4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0),(15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13)),
((15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10),(3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5),(0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15),(13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9)),
((10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8),(13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1),(13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7),(1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12)),
((7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15),(13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9),(10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4),(3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14)),
((2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9),(14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6),(4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14),(11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3)),
((12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11),(10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8),(9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6),(4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13)),
((4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1),(13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6),(1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2),(6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12)),
((13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7),(1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2),(7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8),(2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11)))


def _permute(value: int, table: tuple[int, ...], width: int) -> int:
    out = 0
    for position in table:
        out = (out << 1) | ((value >> (width - position)) & 1)
    return out


def _subkeys(key: int) -> tuple[int, ...]:
    selected = _permute(key, PC1, 64)
    left, right = selected >> 28, selected & ((1 << 28) - 1)
    keys = []
    for shift in SHIFTS:
        left = ((left << shift) | (left >> (28 - shift))) & ((1 << 28) - 1)
        right = ((right << shift) | (right >> (28 - shift))) & ((1 << 28) - 1)
        keys.append(_permute((left << 28) | right, PC2, 56))
    return tuple(keys)


def _f(right: int, key: int, salt: int = 0) -> int:
    expansion = list(E)
    for bit in range(12):
        if (salt >> bit) & 1:
            expansion[bit], expansion[bit + 24] = expansion[bit + 24], expansion[bit]
    mixed = _permute(right, tuple(expansion), 32) ^ key
    substituted = 0
    for box in range(8):
        six = (mixed >> (42 - 6 * box)) & 63
        row = ((six & 32) >> 4) | (six & 1)
        col = (six >> 1) & 15
        substituted = (substituted << 4) | SBOX[box][row][col]
    return _permute(substituted, P, 32)


def _encrypt_block(block: int, keys: tuple[int, ...], salt: int = 0) -> int:
    state = _permute(block, IP, 64)
    left, right = state >> 32, state & 0xFFFFFFFF
    for key in keys:
        left, right = right, left ^ _f(right, key, salt)
    return _permute((right << 32) | left, IP_INV, 64)



CANDIDATES = b" !\"$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}"
CRYPT_ALPHABET = b"./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
MAX_PARSEABLE_INPUT_LENGTH = 8
MAX_OUTPUT_BYTES = 10
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _salt_code(ch: int) -> int:
    if ch == ord("@"):
        return 11  # OpenSSL DES_fcrypt's traditional illegal-salt mapping.
    return CRYPT_ALPHABET.find(bytes((ch,)))


def _normalize_salt(ch: int) -> int:
    if ch < ord(".") or ch > ord("z"):
        ch = ord(".")
    if ord(":") <= ch <= ord("@") or ord("[") <= ch <= ord("`"):
        ch += 6
    return ch


def expected_output(
    values: tuple[int, ...] | list[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null:
        return INVALID_RESULT, b""
    if not isinstance(values, (tuple, list)) or len(values) != MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(v) is not int or v < 0 or v > 127 or v not in CANDIDATES for v in values):
        return INVALID_RESULT, b""
    if output_is_null:
        return OUTPUT_ERROR, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_capacity is not None and output_capacity < 10:
        return OUTPUT_ERROR, b""
    password = bytes(values)
    salt0, salt1 = _normalize_salt(password[1]), _normalize_salt(password[2])
    c0, c1 = _salt_code(salt0), _salt_code(salt1)
    if c0 < 0 or c1 < 0:
        return INVALID_RESULT, b""
    salt = c0 | (c1 << 6)
    key_bytes = bytes((ch << 1) & 255 for ch in password)
    key = int.from_bytes(key_bytes, "big")
    keys = _subkeys(key)
    block = 0
    for _ in range(25):
        block = _encrypt_block(block, keys, salt)
    # DES_fcrypt writes each output word little-endian before encoding 11 groups.
    raw = (block >> 32).to_bytes(4, "little") + (block & 0xffffffff).to_bytes(4, "little")
    encoded = bytearray()
    for group in range(11):
        value = 0
        for j in range(6):
            bit = group * 6 + j
            value <<= 1
            if bit < 64:
                value |= (raw[bit // 8] >> (7 - bit % 8)) & 1
        encoded.append(CRYPT_ALPHABET[value])
    return MAX_OUTPUT_BYTES, bytes(encoded[1:11])
