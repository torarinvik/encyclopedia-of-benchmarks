"""Independent integer oracle for the bounded FreeBench pifft profile."""

from __future__ import annotations

from math import isqrt

FFT_SIZE = 8
SCALE = 1_000_000


def _multiply_fixed(left: int, right: int) -> int:
    """Exact base-1000 convolution, independent of the ports' FFT multiply."""
    product = left * right
    if product < 0:
        return -((-product + SCALE // 2) // SCALE)
    return (product + SCALE // 2) // SCALE


def _sqrt_fixed(value: int) -> int:
    if value <= 0:
        return 0
    radicand = value * SCALE
    root = isqrt(radicand)
    lower_error = radicand - root * root
    upper_error = (root + 1) * (root + 1) - radicand
    return root + 1 if upper_error < lower_error else root


def _half(value: int) -> int:
    return -(abs(value) // 2) if value < 0 else value // 2


def _divide(numerator: int, denominator: int) -> int:
    if denominator <= 0:
        return 0
    scaled = numerator * SCALE
    if scaled < 0:
        return -((-scaled + denominator // 2) // denominator)
    return (scaled + denominator // 2) // denominator


def expected_result(nfft: int) -> int:
    """Return pi rounded to milli-units for the fixed nfft=8 workload."""
    if nfft != FFT_SIZE:
        return -1

    c = _sqrt_fixed(125_000)
    a = SCALE + 3 * c
    b = _sqrt_fixed(a)
    e = b - 625_000
    b *= 2
    c = e - c
    a += e

    npow = 4
    for _ in range(8):
        npow *= 2
        e = _half(a + b)
        b = _sqrt_fixed(_multiply_fixed(a, b))
        e -= b
        b *= 2
        c -= e
        a = e + b
        if -1 <= e <= 1:
            break

    e = _half(e)
    e = _multiply_fixed(e, e)
    a += b
    numerator = _multiply_fixed(a, a) - e - _half(e)
    denominator = _multiply_fixed(a, c) - e
    pi = _divide(numerator, denominator)
    pi = (pi + npow // 2) // npow
    return (pi + 500) // 1000
