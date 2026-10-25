"""Independent scalar oracle for the bounded Rodinia Myocyte CaM RHS."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

INVALID_RESULT = -1.0e300
INPUT_LENGTH = 22


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def _add(a: float, b: float) -> float:
    return _f32(a + b)


def _sub(a: float, b: float) -> float:
    return _f32(a - b)


def _mul(a: float, b: float) -> float:
    return _f32(a * b)


def _div(a: float, b: float) -> float:
    return _f32(a / b)


def _decode(raw: int) -> float:
    # The source ABI converts the integer to float before dividing by 1e6f.
    return _div(_f32(raw), _f32(1_000_000.0))


def expected_result(values: Sequence[int]) -> float:
    """Return the source-ordered weighted checksum, or the invalid sentinel."""
    if len(values) != INPUT_LENGTH:
        return INVALID_RESULT
    if values[0] < 0 or values[0] > 100_000_000:
        return INVALID_RESULT
    if values[1] < 100_000_000 or values[1] > 200_000_000:
        return INVALID_RESULT
    if values[2] < 500_000 or values[2] > 5_000_000:
        return INVALID_RESULT
    if any(value < 0 or value > 10_000_000 for value in values[3:]):
        return INVALID_RESULT

    ca, k, mg = (_decode(values[i]) for i in range(3))
    btot, camkii, cantot, pp1 = (_decode(values[i]) for i in range(3, 7))
    s = [_decode(value) for value in values[7:22]]
    cam, ca2cam, ca4cam, camb, ca2camb, ca4camb = s[:6]
    pb2, pb, pt, pt2, pa = s[6:11]
    ca4can, camca4can, ca2camca4can, ca4camca4can = s[11:15]

    if mg <= _f32(1.0):
        kd02 = _f32(0.0025 * (1.0 + k / 0.94 - mg / 0.012) * (1.0 + k / 8.1 + mg / 0.022))
        kd24 = _f32(0.128 * (1.0 + k / 0.64 + mg / 0.0014) * (1.0 + k / 13.0 - mg / 0.153))
    else:
        kd02 = _f32(0.0025 * (1.0 + k / 0.94 - 1.0 / 0.012 + (mg - 1.0) / 0.060) * (1.0 + k / 8.1 + 1.0 / 0.022 + (mg - 1.0) / 0.068))
        kd24 = _f32(0.128 * (1.0 + k / 0.64 + 1.0 / 0.0014 + (mg - 1.0) / 0.005) * (1.0 + k / 13.0 - 1.0 / 0.153 + (mg - 1.0) / 0.150))
    if not (kd02 > 0.0 and kd24 > 0.0 and math.isfinite(kd02) and math.isfinite(kd24)):
        return INVALID_RESULT

    k20, k42 = _f32(10.0), _f32(500.0)
    k02, k24 = _div(k20, kd02), _div(k42, kd24)
    k0boff = _f32(0.0014)
    k0bon = _f32(float(k0boff) / 0.2)
    k2boff = _div(k0boff, _f32(100.0))
    k2bon, k4boff, k4bon = k0bon, k2boff, k0bon
    k20b, k02b, k42b, k24b = _div(k20, _f32(100.0)), k02, k42, k24
    kbi, kib, kpp1, kmpp1 = _f32(2.2), _f32(float(_f32(2.2)) / 33.5e-3), _f32(1.72), _f32(11.5)
    kib2 = kib
    kb2i, kb24 = _mul(kib2, _f32(5.0)), k24
    kb42 = _f32(float(k42) * 33.5e-3 / 5.0)
    kta, kat = _div(kbi, _f32(1000.0)), kib
    kt42 = _f32(float(k42) * 33.5e-6 / 5.0)
    kt24, kat2, kt2a = k24, kib, _mul(kib, _f32(5.0))
    kcan_caoff = _f32(1.0)
    kcan_caon = _f32(float(kcan_caoff) / 0.5)
    kcan_cam4on, kcan_cam4off = _f32(46.0), _f32(0.0013)
    kcan_cam2on = kcan_cam4on
    kcan_cam2off = _mul(_f32(2508.0), kcan_cam4off)
    kcan_cam0on = kcan_cam4on
    kcan_cam0off = _mul(_f32(165.0), kcan_cam2off)
    k02can, k20can, k24can, k42can = k02, _div(k20, _f32(165.0)), k24, _div(k20, _f32(2508.0))

    ca_sq = float(ca) * float(ca)
    rcn02 = _f32(float(k02) * ca_sq * float(cam) - float(k20) * float(ca2cam))
    rcn24 = _f32(float(k24) * ca_sq * float(ca2cam) - float(k42) * float(ca4cam))
    b = _sub(_sub(_sub(btot, camb), ca2camb), ca4camb)
    rcn02b = _f32(float(k02b) * ca_sq * float(camb) - float(k20b) * float(ca2camb))
    rcn24b = _f32(float(k24b) * ca_sq * float(ca2camb) - float(k42b) * float(ca4camb))
    rcn0b = _sub(_mul(_mul(k0bon, cam), b), _mul(k0boff, camb))
    rcn2b = _sub(_mul(_mul(k2bon, ca2cam), b), _mul(k2boff, ca2camb))
    rcn4b = _sub(_mul(_mul(k4bon, ca4cam), b), _mul(k4boff, ca4camb))
    ca2can = _sub(_sub(_sub(_sub(cantot, ca4can), camca4can), ca2camca4can), ca4camca4can)
    rcn_ca4can = _f32(float(kcan_caon) * ca_sq * float(ca2can) - float(kcan_caoff) * float(ca4can))
    rcn02can = _f32(float(k02can) * ca_sq * float(camca4can) - float(k20can) * float(ca2camca4can))
    rcn24can = _f32(float(k24can) * ca_sq * float(ca2camca4can) - float(k42can) * float(ca4camca4can))
    rcn0can = _sub(_mul(_mul(kcan_cam0on, cam), ca4can), _mul(kcan_cam0off, camca4can))
    rcn2can = _sub(_mul(_mul(kcan_cam2on, ca2cam), ca4can), _mul(kcan_cam2off, ca2camca4can))
    rcn4can = _sub(_mul(_mul(kcan_cam4on, ca4cam), ca4can), _mul(kcan_cam4off, ca4camca4can))

    pix = _sub(_sub(_sub(_sub(_sub(_f32(1.0), pb2), pb), pt), pt2), pa)
    rcn_ckib2 = _sub(_mul(_mul(kib2, ca2cam), pix), _mul(kb2i, pb2))
    rcn_ckb2b = _f32(float(kb24) * ca_sq * float(pb2) - float(kb42) * float(pb))
    rcn_ckib = _sub(_mul(_mul(kib, ca4cam), pix), _mul(kbi, pb))
    total = _add(_add(_add(pb, pt), pt2), pa)
    kbt = _f32(0.055 * total + 0.0074 * total * total + 0.015 * total * total * total)
    rcn_ckbt = _sub(_mul(kbt, pb), _div(_mul(_mul(kpp1, pp1), pt), _add(kmpp1, _mul(camkii, pt))))
    rcn_cktt2 = _sub(_mul(kt42, pt), _f32(float(kt24) * ca_sq * float(pt2)))
    rcn_ckta = _sub(_mul(kta, pt), _mul(_mul(kat, ca4cam), pa))
    rcn_ckt2a = _sub(_mul(kt2a, pt2), _mul(_mul(kat2, ca2cam), pa))
    rcn_ckt2b2 = _div(_mul(_mul(kpp1, pp1), pt2), _add(kmpp1, _mul(camkii, pt2)))
    rcn_ckai = _div(_mul(_mul(kpp1, pp1), pa), _add(kmpp1, _mul(camkii, pa)))

    d: list[float] = [0.0] * 16
    d[0] = _f32(1e-3 * float(_sub(_sub(-rcn02, rcn0b), rcn0can)))
    term = _add(_sub(_sub(_sub(rcn02, rcn24), rcn2b), rcn2can), _mul(camkii, _add(-rcn_ckib2, rcn_ckt2a)))
    d[1] = _f32(1e-3 * float(term))
    term = _add(_sub(_sub(rcn24, rcn4b), rcn4can), _mul(camkii, _add(-rcn_ckib, rcn_ckta)))
    d[2] = _f32(1e-3 * float(term))
    d[3] = _f32(1e-3 * float(_sub(rcn0b, rcn02b)))
    d[4] = _f32(1e-3 * float(_sub(_add(rcn02b, rcn2b), rcn24b)))
    d[5] = _f32(1e-3 * float(_add(rcn24b, rcn4b)))
    d[6] = _f32(1e-3 * float(_add(_sub(rcn_ckib2, rcn_ckb2b), rcn_ckt2b2)))
    d[7] = _f32(1e-3 * float(_sub(_add(rcn_ckib, rcn_ckb2b), rcn_ckbt)))
    d[8] = _f32(1e-3 * float(_sub(_sub(rcn_ckbt, rcn_ckta), rcn_cktt2)))
    d[9] = _f32(1e-3 * float(_sub(_sub(rcn_cktt2, rcn_ckt2a), rcn_ckt2b2)))
    d[10] = _f32(1e-3 * float(_sub(_add(rcn_ckta, rcn_ckt2a), rcn_ckai)))
    d[11] = _f32(1e-3 * float(_sub(_sub(_sub(rcn_ca4can, rcn0can), rcn2can), rcn4can)))
    d[12] = _f32(1e-3 * float(_sub(rcn0can, rcn02can)))
    d[13] = _f32(1e-3 * float(_add(_add(rcn2can, rcn02can), rcn24can)))
    d[14] = _f32(1e-3 * float(_add(rcn4can, rcn24can)))
    comm = _add(_add(_add(_add(_add(_add(rcn02, rcn24), rcn02b), rcn24b), rcn_ca4can), rcn02can), rcn24can)
    comterm = _mul(_mul(_f32(2.0), camkii), _sub(rcn_cktt2, rcn_ckb2b))
    d[15] = _f32(1e-3 * float(_sub(comterm, _mul(_f32(2.0), comm))))
    return sum((index + 1) * float(value) for index, value in enumerate(d))
