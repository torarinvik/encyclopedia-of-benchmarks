"""Independent binary32 oracle for VersaBench's complex BeamForm stage."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

CHANNELS = 12
INPUT_LENGTH = 4 * CHANNELS
MAX_INPUT_LENGTH = INPUT_LENGTH
MAX_OUTPUT_ELEMENTS = 2
MAX_ABS_VALUE = 128.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2
PINNED_SOURCE = {
    "repository": "lac-dcc/Benchmarks",
    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
    "path": "VersaBench/beamformer/beamformer.c",
    "symbols": ["BeamForm"],
    "url": "https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/beamformer/beamformer.c",
    "role": "algorithm",
}


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, ()
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, ()
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values) or declared != INPUT_LENGTH:
        return INVALID_RESULT, ()
    if any(type(value) not in (int, float) or not math.isfinite(value) or abs(value) > MAX_ABS_VALUE for value in values):
        return INVALID_RESULT, ()
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, ()

    real = _f32(0.0)
    imag = _f32(0.0)
    narrowed = [_f32(float(value)) for value in values]
    for channel in range(CHANNELS):
        base = 4 * channel
        wr, wi, xr, xi = narrowed[base:base + 4]
        rr = _f32(_f32(wr * xr) - _f32(wi * xi))
        ii = _f32(_f32(wr * xi) + _f32(wi * xr))
        real = _f32(real + rr)
        imag = _f32(imag + ii)

    if output_is_null or (output_capacity is not None and output_capacity < 2):
        return OUTPUT_ERROR, ()
    return 2, (float(real), float(imag))
