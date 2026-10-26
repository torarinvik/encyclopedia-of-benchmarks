"""Source-shaped binary32 model of Rodinia Heartwall template matching."""

import math
import struct
from collections.abc import Sequence

INVALID_RESULT = -1
NULL_OR_SHORT_RESULT = -2
MAX_INPUT_LENGTH = 85
MAX_CANDIDATES = 49
MAX_OUTPUT_BYTES = 8


def f32(x: float) -> float:
    return struct.unpack("<f", struct.pack("<f", float(x)))[0]


def _add(a, b): return f32(a + b)
def _sub(a, b): return f32(a - b)
def _mul(a, b): return f32(a * b)
def _div(a, b): return f32(a / b)


def select_candidate(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(v) is not int for v in values):
        return INVALID_RESULT
    ir, ic, tr, tc, mask = values[:5]
    if not (2 <= ir <= 8 and 2 <= ic <= 8 and 2 <= tr <= 4 and 2 <= tc <= 4
            and tr <= ir and tc <= ic and mask >= 0):
        return INVALID_RESULT
    count = (ir - tr + 1) * (ic - tc + 1)
    if mask >> count or len(values) != 5 + tr * tc + ir * ic:
        return INVALID_RESULT
    tv = values[5:5 + tr * tc]
    iv = values[5 + tr * tc:]
    if any(x < 0 or x > 255 for x in tv) or any(x < 0 or x > 255 for x in iv):
        return INVALID_RESULT

    n = tr * tc
    tsum = f32(0.0)
    tsq = f32(0.0)
    for x in tv:
        xf = f32(x)
        tsum = _add(tsum, xf)
        tsq = _add(tsq, _mul(xf, xf))
    nf = f32(n)
    tmean = _div(tsum, nf)
    tvar = _sub(_div(tsq, nf), _mul(tmean, tmean))
    if not (tvar > 0.0):
        return INVALID_RESULT
    tscale = _mul(f32(math.sqrt(f32(n - 1))), f32(math.sqrt(tvar)))

    best_index = 0
    best_abs = f32(0.0)
    candidate = 0
    # Source buffers are column-major. Candidate positions are enumerated with
    # row varying fastest, matching the source's column-major mask traversal.
    for c0 in range(ic - tc + 1):
        for r0 in range(ir - tr + 1):
            if (mask >> candidate) & 1:
                psum = f32(0.0)
                psq = f32(0.0)
                dot = f32(0.0)
                for c in range(tc):
                    for r in range(tr):
                        a = f32(tv[c * tr + r])
                        b = f32(iv[(c0 + c) * ir + (r0 + r)])
                        psum = _add(psum, b)
                        psq = _add(psq, _mul(b, b))
                        dot = _add(dot, _mul(a, b))
                pcenter = _sub(psq, _div(_mul(psum, psum), nf))
                if pcenter < 0.0:
                    pcenter = f32(0.0)
                if not (pcenter > 0.0):
                    return INVALID_RESULT
                numerator = _sub(dot, _div(_mul(psum, tsum), nf))
                denom = _mul(f32(math.sqrt(pcenter)), tscale)
                score = _div(numerator, denom)
                score_abs = abs(score)
                if not math.isfinite(score_abs):
                    return INVALID_RESULT
                if score_abs > best_abs:
                    best_abs = score_abs
                    best_index = candidate
            candidate += 1
    return best_index


def expected_bytes(values: Sequence[int]) -> tuple[int, bytes]:
    result = select_candidate(values)
    if result < 0:
        return result, b""
    return 8, int(result).to_bytes(8, "little", signed=True)
