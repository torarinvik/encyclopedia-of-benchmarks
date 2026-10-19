"""Independent oracle for the bounded Trimaran ARC4 validation profile."""

from __future__ import annotations

MIN_PASSES = 1
MAX_PASSES = 2_000
MAX_INPUT_VALUES = 1
MAX_PARSEABLE_INPUT_VALUES = 2
MAX_OUTPUT_BYTES = 82
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_VECTORS = (
    (bytes.fromhex("0123456789abcdef"), bytes.fromhex("0123456789abcdef")),
    (bytes.fromhex("0123456789abcdef"), bytes.fromhex("0000000000000000")),
    (bytes.fromhex("0000000000000000"), bytes.fromhex("0000000000000000")),
    (bytes.fromhex("ef012345"), bytes.fromhex("00" * 20)),
    (bytes.fromhex("0123456789abcdef"), bytes.fromhex("123456789abcdef0" * 3 + "12345678")),
    (bytes.fromhex("ef012345"), bytes.fromhex("00" * 10)),
)


def _crypt(key: bytes, data: bytes) -> bytes:
    state = list(range(256))
    j = 0
    for i in range(256):
        j = (j + state[i] + key[i % len(key)]) & 0xFF
        state[i], state[j] = state[j], state[i]

    output = bytearray(data)
    i = 0
    j = 0
    for offset, byte in enumerate(data):
        i = (i + 1) & 0xFF
        j = (j + state[i]) & 0xFF
        state[i], state[j] = state[j], state[i]
        output[offset] = byte ^ state[(state[i] + state[j]) & 0xFF]
    return bytes(output)


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if not isinstance(values, (list, tuple)) or len(values) != 1:
        return INVALID_RESULT, b""
    passes = values[0]
    if type(passes) is not int or not MIN_PASSES <= passes <= MAX_PASSES:
        return INVALID_RESULT, b""

    ciphertexts = []
    for key, data in _VECTORS:
        ciphertext = b""
        for _ in range(passes):
            ciphertext = _crypt(key, data)
        ciphertexts.append(ciphertext)
    output = b"".join(ciphertexts)
    return len(output), output
