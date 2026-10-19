"""Independent integer-only oracle for bounded NBench InternalFPF arithmetic."""
from __future__ import annotations
import struct
from typing import Sequence

MAX_OPS = 8
MAX_INPUT_LENGTH = 1 + 13 * MAX_OPS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 12 * MAX_OPS
MIN_EXP = -32767
MASK64 = (1 << 64) - 1


def _shr_sticky(m: int, count: int) -> int:
    for _ in range(count):
        lost = m & 1
        m >>= 1
        if lost:
            m |= 1
    return m


def _addsub(x: tuple[int, int, int], y: tuple[int, int, int], op: int) -> tuple[int, int, int, int]:
    sx, ex, mx = x
    sy, ey, my = y
    zsign, zexp = sx, ex
    diff = ex - ey
    if diff > 0:
        my = _shr_sticky(my, diff)
    elif diff < 0:
        mx = _shr_sticky(mx, -diff)
        zsign, zexp = sy ^ op, ey
    if sx ^ sy ^ op:
        mant = (mx - my) & MASK64
        if mx < my:
            zsign, mant = sy ^ op, (my - mx) & MASK64
        if mant == 0:
            typ, zsign, zexp = 0, 0, MIN_EXP
        else:
            typ = 2
            while (mant >> 63) == 0:
                mant = (mant << 1) & MASK64
                zexp -= 1
    else:
        typ = 2
        mant = (mx + my) & MASK64
        if mx + my > MASK64:
            zexp += 1
            mant = (mant >> 1) | (1 << 63)
    if typ == 2:
        mant &= ~7
    return typ, zsign, zexp, mant


def _multiply(x: tuple[int, int, int], y: tuple[int, int, int]) -> tuple[int, int, int, int]:
    sx, ex, mx = x
    sy, ey, my = y
    zexp = ex + ey
    high = low = 0
    for _ in range(64):
        carry = 0
        if my & 1:
            total = high + mx
            high = total & MASK64
            carry = int(total > MASK64)
        my >>= 1
        outgoing = high & 1
        high = (high >> 1) | (carry << 63)
        low = (low >> 1) | (outgoing << 63)
    while (high >> 63) == 0:
        carry = low >> 63
        low = (low << 1) & MASK64
        high = ((high << 1) | carry) & MASK64
        zexp -= 1
    if low == 0:
        high |= 1
    high &= ~7
    return 2, sx ^ sy, zexp, high


def _divide(x: tuple[int, int, int], y: tuple[int, int, int]) -> tuple[int, int, int, int]:
    sx, ex, dividend = x
    sy, ey, divisor = y
    zexp = ex - ey + 128
    quotient = remainder = 0
    while (quotient >> 63) == 0:
        carry = dividend >> 63
        dividend = (dividend << 1) & MASK64
        remainder_overflow = remainder >> 63
        remainder = ((remainder << 1) | carry) & MASK64
        bit = 0
        if remainder_overflow or remainder >= divisor:
            remainder = (remainder - divisor) & MASK64
            bit = 1
        quotient = ((quotient << 1) | bit) & MASK64
        zexp -= 1
    quotient &= ~7
    return 2, sx ^ sy, zexp, quotient


def _record(result: tuple[int, int, int, int]) -> bytes:
    typ, sign, exp, mant = result
    words = [(mant >> (48 - 16 * i)) & 0xFFFF for i in range(4)]
    return struct.pack("<BBh4H", typ, sign, exp, *words)


def expected_output(values: Sequence[int] | None, output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or values is None or not isinstance(values, (tuple, list)):
        return -1, b""
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_OPS or len(values) != 1 + 13 * n:
        return -1, b""
    results = []
    for i in range(n):
        p = 1 + 13 * i
        op, sx, ex = values[p:p+3]
        mx_words = values[p+3:p+7]
        sy, ey = values[p+7:p+9]
        my_words = values[p+9:p+13]
        if op not in range(4) or sx not in (0, 1) or sy not in (0, 1):
            return -1, b""
        if not -8 <= ex <= 8 or not -8 <= ey <= 8:
            return -1, b""
        if any(not 0 <= w <= 0xFFFF for w in (*mx_words, *my_words)):
            return -1, b""
        mx = my = 0
        for w in mx_words: mx = (mx << 16) | w
        for w in my_words: my = (my << 16) | w
        if mx >> 63 == 0 or my >> 63 == 0:
            return -1, b""
        x, y = (sx, ex, mx), (sy, ey, my)
        if op < 2:
            result = _addsub(x, y, op)
        elif op == 2:
            result = _multiply(x, y)
        else:
            result = _divide(x, y)
        if result[0] == 2 and (not -32 <= result[2] <= 32 or result[3] >> 63 == 0):
            return -1, b""
        results.append(_record(result))
    payload = b"".join(results)
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
