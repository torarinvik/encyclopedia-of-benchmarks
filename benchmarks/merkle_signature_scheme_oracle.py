"""Independent verifier oracle for the pinned Java Merkle signature scheme."""

from __future__ import annotations

import hashlib
import struct

MAX_INPUT_VALUES = 8932
MAX_OUTPUT_BYTES = 8
_WOTS = {4: (2, 133, 128, 5), 16: (4, 67, 64, 3), 256: (8, 34, 32, 2)}


def _digits(message: bytes, w: int) -> list[int]:
    log_w, _, len1, len2 = _WOTS[w]
    digest = hashlib.sha256(message).digest()
    mask = w - 1
    values: list[int] = []
    for byte in digest:
        shift = 8 - log_w
        while shift >= 0:
            values.append((byte >> shift) & mask)
            shift -= log_w
    checksum = sum(mask - digit for digit in values)
    suffix = [0] * len2
    for index in range(len2 - 1, -1, -1):
        suffix[index] = checksum & mask
        checksum >>= log_w
    assert len(values) == len1
    return values + suffix


def _hash(data: bytes) -> bytes:
    return hashlib.sha256(data).digest()


def _verify(message: bytes, w: int, signature: list[bytes], public_key: list[bytes],
            auth: list[bytes], leaf_index: int, root: bytes) -> bool:
    digits = _digits(message, w)
    for i, digit in enumerate(digits):
        current = signature[i]
        for _ in range(w - 1 - digit):
            current = _hash(current)
        if current != public_key[i]:
            return False
    node = _hash(b"".join(public_key))
    index = leaf_index
    for sibling in auth:
        node = _hash(node + sibling) if index % 2 == 0 else _hash(sibling + node)
        index >>= 1
    return node == root


def expected_output(values: list[int] | tuple[int, ...] | None,
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return one little-endian signed i64 boolean, or an ABI error code."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (not 4 <= len(values) <= MAX_INPUT_VALUES
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    height, w, message_len = values[:3]
    if not 2 <= height <= 10 or w not in _WOTS or not 0 <= message_len <= 64:
        return -1, b""
    _, length, _, _ = _WOTS[w]
    needed = 4 + message_len + 64 * length + 32 * height + 32
    if len(values) != needed:
        return -1, b""
    message_start = 3
    message_values = values[message_start:message_start + message_len]
    if any(not 0 <= byte <= 127 for byte in message_values):
        return -1, b""
    index_pos = message_start + message_len
    leaf_index = values[index_pos]
    if not 0 <= leaf_index < (1 << height):
        return -1, b""
    position = index_pos + 1
    sig_values = values[position:position + 32 * length]
    position += 32 * length
    pub_values = values[position:position + 32 * length]
    position += 32 * length
    auth_values = values[position:position + 32 * height]
    position += 32 * height
    root_values = values[position:position + 32]
    if any(not 0 <= byte <= 255 for byte in (*sig_values, *pub_values, *auth_values, *root_values)):
        return -1, b""
    signature = [bytes(sig_values[i:i + 32]) for i in range(0, len(sig_values), 32)]
    public_key = [bytes(pub_values[i:i + 32]) for i in range(0, len(pub_values), 32)]
    auth = [bytes(auth_values[i:i + 32]) for i in range(0, len(auth_values), 32)]
    result = int(_verify(bytes(message_values), w, signature, public_key, auth,
                         leaf_index, bytes(root_values)))
    if capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return MAX_OUTPUT_BYTES, struct.pack("<q", result)
