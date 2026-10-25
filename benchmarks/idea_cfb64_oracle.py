"""Independent IDEA-CFB64 oracle for the bounded PGP helper profile."""
from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_BYTES = 24
MAX_INPUT_LENGTH = 26 + MAX_TEXT_BYTES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_TEXT_BYTES


def _mul(a: int, b: int) -> int:
    x = a or 65536
    y = b or 65536
    z = (x * y) % 65537
    return 0 if z == 65536 else z


def _subkeys(key: bytes) -> list[int]:
    state = [int.from_bytes(key[i:i+2], "big") for i in range(0, 16, 2)]
    result: list[int] = []
    while len(result) < 52:
        result.extend(state[:min(8, 52-len(result))])
        state = [((state[(i+1)&7] << 9) | (state[(i+2)&7] >> 7)) & 0xFFFF
                 for i in range(8)]
    return result


def _encrypt_block(subkeys: Sequence[int], block: bytes) -> bytes:
    x1, x2, x3, x4 = (int.from_bytes(block[i:i+2], "big") for i in range(0, 8, 2))
    for rnd in range(8):
        k = subkeys[rnd*6:rnd*6+6]
        a = _mul(x1, k[0])
        b = (x2 + k[1]) & 0xFFFF
        c = (x3 + k[2]) & 0xFFFF
        d = _mul(x4, k[3])
        p = _mul(a ^ c, k[4])
        q = _mul((b ^ d) + p & 0xFFFF, k[5])
        t = (p + q) & 0xFFFF
        x1, x2, x3, x4 = a ^ q, c ^ q, b ^ t, d ^ t
    words = (_mul(x1, subkeys[48]), (x3 + subkeys[49]) & 0xFFFF,
             (x2 + subkeys[50]) & 0xFFFF, _mul(x4, subkeys[51]))
    return b"".join(word.to_bytes(2, "big") for word in words)


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    if not 27 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    mode, text_len = values[0], values[1]
    if mode not in (0, 1) or not 1 <= text_len <= MAX_TEXT_BYTES or len(values) != 26 + text_len:
        return -1, b""
    payload = values[2:]
    if any(not 0 <= b <= 255 for b in payload):
        return -1, b""
    key = bytes(payload[:16])
    state = bytes(payload[16:24])
    data = bytes(payload[24:])
    subkeys = _subkeys(key)
    cipher = bytearray()
    for pos in range(0, len(data), 8):
        stream = _encrypt_block(subkeys, state)
        chunk = data[pos:pos+8]
        transformed = bytes(a ^ b for a, b in zip(chunk, stream))
        cipher.extend(transformed)
        feedback = transformed if mode == 0 else chunk
        state = feedback + state[len(feedback):]
    output = bytes(cipher)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output


oracle = expected_output
