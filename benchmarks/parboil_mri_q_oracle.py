"""Independent bounded direct nonuniform Fourier profile for Parboil MRI-Q."""

from collections.abc import Sequence
import math
import struct

MAX_K = 4
MAX_COMPONENT_RAW = 1_000_000
MAX_INPUT_LENGTH = 4 + 5 * MAX_K
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
OUTPUT_BYTES = 8
MAX_OUTPUT_BYTES = OUTPUT_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
OUTPUT_SCALE = 1_000
PI_X_2 = struct.unpack("<f", struct.pack("<f", 6.2831853071795864769252867665590058))[0]


def _f32(value: float | int) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _decode(raw: int) -> float:
    return _f32(_f32(raw) / _f32(1_000_000))


def _quantize(value: float) -> int:
    scaled = _f32(_f32(value) * _f32(OUTPUT_SCALE))
    magnitude = _f32(abs(scaled))
    whole = int(magnitude)
    fraction = _f32(magnitude - _f32(whole))
    if fraction >= 0.5:
        whole += 1
    return -whole if scaled < 0.0 else whole


def _compute_output(values: Sequence[int], input_length: int | None = None) -> bytes | None:
    if not isinstance(values, (tuple, list)) or not 9 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int for value in values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_K or len(values) != 4 + 5 * count:
        return None
    if any(abs(value) > MAX_COMPONENT_RAW for value in values[1:]):
        return None

    x, y, z = (_decode(value) for value in values[1:4])
    records: list[tuple[float, float, float, float, float]] = []
    phi_magnitudes: list[float] = []
    for k in range(count):
        offset = 4 + 5 * k
        kx, ky, kz, phi_real, phi_imag = (_decode(value) for value in values[offset:offset + 5])
        real_square = _f32(phi_real * phi_real)
        imag_square = _f32(phi_imag * phi_imag)
        phi_magnitudes.append(_f32(real_square + imag_square))
        records.append((kx, ky, kz, phi_real, phi_imag))

    qr = _f32(0.0)
    qi = _f32(0.0)
    for k, (kx, ky, kz, _phi_real, _phi_imag) in enumerate(records):
        kx_x = _f32(kx * x)
        ky_y = _f32(ky * y)
        kz_z = _f32(kz * z)
        xy = _f32(kx_x + ky_y)
        xyz = _f32(xy + kz_z)
        phase = _f32(PI_X_2 * xyz)
        # The ports call their host's binary32 sine/cosine; this independent
        # oracle evaluates in binary64 and rounds the results to binary32.
        cos_phase = _f32(math.cos(phase))
        sin_phase = _f32(math.sin(phase))
        qr_term = _f32(phi_magnitudes[k] * cos_phase)
        qi_term = _f32(phi_magnitudes[k] * sin_phase)
        qr = _f32(qr + qr_term)
        qi = _f32(qi + qi_term)

    return struct.pack("<ii", _quantize(qr), _quantize(qi))


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or values is not None and not isinstance(values, (tuple, list))
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, (), [])
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    payload = _compute_output(values, input_length)
    if payload is None:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity is not None and output_capacity < OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, payload
