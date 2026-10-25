"""Independent binary32 oracle for the bounded RSynth impulse/resonator profile."""
from __future__ import annotations
import math
import struct
from collections.abc import Sequence

MIN_OPEN, MAX_OPEN = 40, 263
MAX_SAMPLE_INDEX = 299
MAX_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_ELEMENTS = 1
SAMPLE_RATE = 8000

def _f32(x: float) -> float:
    return struct.unpack('>f', struct.pack('>f', x))[0]

def expected_output(values: Sequence[float] | None,
                    output_capacity: int | None = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in values)):
        return -1, ()
    if len(values) != 2 or any(not float(v).is_integer() for v in values): return -1, ()
    nopen, sample_index = (int(v) for v in values)
    if not MIN_OPEN <= nopen <= MAX_OPEN or not 0 <= sample_index <= MAX_SAMPLE_INDEX:
        return -1, ()

    # nsynth.c::pitch_synch_par_reset, using linuxplay.c's pinned default rate.
    minus_pi_t = _f32(-math.pi / SAMPLE_RATE)
    two_pi_t = _f32(-2.0 * minus_pi_t)
    bandwidth = SAMPLE_RATE // nopen
    r = _f32(math.exp(float(minus_pi_t) * bandwidth))
    c = _f32(-(r * r))
    b = _f32(float(r) * math.cos(float(two_pi_t) * 0.0) * 2.0)
    a = _f32(1.0 - float(b) - float(c))
    temp1 = _f32(nopen * 0.00833)
    a = _f32(a * _f32(temp1 * temp1))
    p1 = p2 = _f32(0.0)
    result = _f32(0.0)
    for nper in range(sample_index + 1):
        inp = _f32(0.0 if nper == 0 else 13_000_000.0 if nper == 1 else -13_000_000.0 if nper == 2 else 0.0)
        x = _f32(_f32(a * inp) + _f32(b * p1))
        x = _f32(x + _f32(c * p2))
        p2, p1 = p1, x
        result = x
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, ()
    if output_is_null or output_capacity < 1: return -2, ()
    return 1, (float(result),)

oracle = expected_output
