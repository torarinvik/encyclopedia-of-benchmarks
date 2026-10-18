"""Oracle for the pinned Rust SHA-2 variants."""

from __future__ import annotations

import hashlib
from collections.abc import Sequence

MAX_MESSAGE_BYTES = 4096
MAX_VALID_INPUT_LENGTH = 2 + MAX_MESSAGE_BYTES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 64

INVALID_RESULT = -1
OUTPUT_ERROR = -2

_MASK64 = (1 << 64) - 1
_K64 = (
    0x428A2F98D728AE22, 0x7137449123EF65CD, 0xB5C0FBCFEC4D3B2F, 0xE9B5DBA58189DBBC,
    0x3956C25BF348B538, 0x59F111F1B605D019, 0x923F82A4AF194F9B, 0xAB1C5ED5DA6D8118,
    0xD807AA98A3030242, 0x12835B0145706FBE, 0x243185BE4EE4B28C, 0x550C7DC3D5FFB4E2,
    0x72BE5D74F27B896F, 0x80DEB1FE3B1696B1, 0x9BDC06A725C71235, 0xC19BF174CF692694,
    0xE49B69C19EF14AD2, 0xEFBE4786384F25E3, 0x0FC19DC68B8CD5B5, 0x240CA1CC77AC9C65,
    0x2DE92C6F592B0275, 0x4A7484AA6EA6E483, 0x5CB0A9DCBD41FBD4, 0x76F988DA831153B5,
    0x983E5152EE66DFAB, 0xA831C66D2DB43210, 0xB00327C898FB213F, 0xBF597FC7BEEF0EE4,
    0xC6E00BF33DA88FC2, 0xD5A79147930AA725, 0x06CA6351E003826F, 0x142929670A0E6E70,
    0x27B70A8546D22FFC, 0x2E1B21385C26C926, 0x4D2C6DFC5AC42AED, 0x53380D139D95B3DF,
    0x650A73548BAF63DE, 0x766A0ABB3C77B2A8, 0x81C2C92E47EDAEE6, 0x92722C851482353B,
    0xA2BFE8A14CF10364, 0xA81A664BBC423001, 0xC24B8B70D0F89791, 0xC76C51A30654BE30,
    0xD192E819D6EF5218, 0xD69906245565A910, 0xF40E35855771202A, 0x106AA07032BBD1B8,
    0x19A4C116B8D2D0C8, 0x1E376C085141AB53, 0x2748774CDF8EEB99, 0x34B0BCB5E19B48A8,
    0x391C0CB3C5C95A63, 0x4ED8AA4AE3418ACB, 0x5B9CCA4F7763E373, 0x682E6FF3D6B2B8A3,
    0x748F82EE5DEFB2FC, 0x78A5636F43172F60, 0x84C87814A1F0AB72, 0x8CC702081A6439EC,
    0x90BEFFFA23631E28, 0xA4506CEBDE82BDE9, 0xBEF9A3F7B2C67915, 0xC67178F2E372532B,
    0xCA273ECEEA26619C, 0xD186B8C721C0C207, 0xEADA7DD6CDE0EB1E, 0xF57D4F7FEE6ED178,
    0x06F067AA72176FBA, 0x0A637DC5A2C898A6, 0x113F9804BEF90DAE, 0x1B710B35131C471B,
    0x28DB77F523047D84, 0x32CAAB7B40C72493, 0x3C9EBE0A15C9BEBc, 0x431D67C49C100D4C,
    0x4CC5D4BECb3E42B6, 0x597F299CFC657E2A, 0x5FCB6FAB3AD6FAEC, 0x6C44198C4A475817,
)
_H512_224 = (
    0x8C3D37C819544DA2, 0x73E1996689DCD4D6, 0x1DFAB7AE32FF9C82, 0x679DD514582F9FCF,
    0x0F6D2B697BD44DA8, 0x77E36F7304C48942, 0x3F9D85A86A1D36C8, 0x1112E6AD91D692A1,
)
_H512_256 = (
    0x22312194FC2BF72C, 0x9F555FA3C84C64C2, 0x2393B86B6F53B151, 0x963877195940EABD,
    0x96283EE2A88EFFE3, 0xBE5E1E2553863992, 0x2B0199FC2C85B8AA, 0x0EB72DDC81C52CA2,
)


def _rotr64(value: int, amount: int) -> int:
    return ((value >> amount) | (value << (64 - amount))) & _MASK64


def _sha512_t_fallback(message: bytes, initial_state: tuple[int, ...], digest_bytes: int) -> bytes:
    """Pure-Python pinned SHA-512/t path for runtimes without hashlib support."""
    padded = bytearray(message)
    padded.append(0x80)
    while len(padded) % 128 != 112:
        padded.append(0)
    padded.extend((len(message) * 8).to_bytes(16, "big"))
    state = list(initial_state)

    for offset in range(0, len(padded), 128):
        block = padded[offset:offset + 128]
        words = [int.from_bytes(block[index:index + 8], "big") for index in range(0, 128, 8)]
        for index in range(16, 80):
            x = words[index - 15]
            y = words[index - 2]
            sigma0 = _rotr64(x, 1) ^ _rotr64(x, 8) ^ (x >> 7)
            sigma1 = _rotr64(y, 19) ^ _rotr64(y, 61) ^ (y >> 6)
            words.append((words[index - 16] + sigma0 + words[index - 7] + sigma1) & _MASK64)

        a, b, c, d, e, f, g, h = state
        for index in range(80):
            big_sigma1 = _rotr64(e, 14) ^ _rotr64(e, 18) ^ _rotr64(e, 41)
            choose = (e & f) ^ ((~e) & g)
            temp1 = (h + big_sigma1 + choose + _K64[index] + words[index]) & _MASK64
            big_sigma0 = _rotr64(a, 28) ^ _rotr64(a, 34) ^ _rotr64(a, 39)
            majority = (a & b) ^ (a & c) ^ (b & c)
            temp2 = (big_sigma0 + majority) & _MASK64
            h, g, f, e, d, c, b, a = g, f, e, (d + temp1) & _MASK64, c, b, a, (temp1 + temp2) & _MASK64
        state = [(old + new) & _MASK64 for old, new in zip(state, (a, b, c, d, e, f, g, h))]

    return b"".join(word.to_bytes(8, "big") for word in state)[:digest_bytes]


def _digest(variant: int, message: bytes) -> bytes:
    standard_hashes = (hashlib.sha224, hashlib.sha256, hashlib.sha384, hashlib.sha512)
    if variant < 4:
        return standard_hashes[variant](message).digest()
    algorithm = "sha512_224" if variant == 4 else "sha512_256"
    try:
        return hashlib.new(algorithm, message).digest()
    except ValueError:
        initial_state, digest_bytes = (
            (_H512_224, 28) if variant == 4 else (_H512_256, 32)
        )
        return _sha512_t_fallback(message, initial_state, digest_bytes)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the selected SHA-2 digest or the documented ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if (
        not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values
        )
    ):
        return INVALID_RESULT, b""
    if len(values) < 2:
        return INVALID_RESULT, b""

    variant, message_length = values[:2]
    if not 0 <= variant <= 5 or not 0 <= message_length <= MAX_MESSAGE_BYTES:
        return INVALID_RESULT, b""
    if len(values) != 2 + message_length:
        return INVALID_RESULT, b""
    message_values = values[2:]
    if any(not 0 <= value <= 255 for value in message_values):
        return INVALID_RESULT, b""

    digest = _digest(variant, bytes(message_values))
    if output_is_null or (
        output_capacity is not None and output_capacity < len(digest)
    ):
        return OUTPUT_ERROR, b""
    return len(digest), digest
