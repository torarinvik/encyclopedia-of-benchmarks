"""Independent bounded reference for the MediaBench G.721/u-law encoder."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_SAMPLES = 16
MAX_INPUT_LENGTH = MAX_SAMPLES + 1
MAX_OUTPUT_BYTES = (MAX_SAMPLES + 1) // 2

_POWERS_OF_TWO = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384)
_QUANT_THRESHOLDS = (-124, 80, 178, 246, 300, 349, 400)
_LOG_DELTA = (-2048, 4, 135, 213, 273, 323, 373, 425, 425, 373, 323, 273, 213, 135, 4, -2048)
_SCALE_STEP = (-12, 18, 41, 64, 112, 198, 355, 1122, 1122, 355, 198, 112, 64, 41, 18, -12)
_ENERGY_STEP = (0, 0, 0, 512, 512, 512, 1536, 3584, 3584, 1536, 512, 512, 512, 0, 0, 0)


def _short(value: int) -> int:
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def _threshold_index(value: int, limits: Sequence[int]) -> int:
    for position, limit in enumerate(limits):
        if value < limit:
            return position
    return len(limits)


def _coefficient_product(coefficient: int, encoded: int) -> int:
    magnitude = coefficient if coefficient > 0 else ((-coefficient) & 0x1FFF)
    exponent = _threshold_index(magnitude, _POWERS_OF_TWO) - 6
    if magnitude == 0:
        mantissa = 32
    elif exponent >= 0:
        mantissa = magnitude >> exponent
    else:
        mantissa = magnitude << -exponent
    product_exponent = exponent + ((encoded >> 6) & 0x0F) - 13
    product_mantissa = (mantissa * (encoded & 0o77) + 0x30) >> 4
    if product_exponent >= 0:
        result = (product_mantissa << product_exponent) & 0x7FFF
    else:
        result = product_mantissa >> -product_exponent
    return -result if (coefficient ^ encoded) < 0 else result


def _predict(state: dict[str, object]) -> tuple[int, int]:
    b = state["b"]
    dq = state["dq"]
    a = state["a"]
    sr = state["sr"]
    assert isinstance(b, list) and isinstance(dq, list)
    assert isinstance(a, list) and isinstance(sr, list)
    zero_prediction = sum(_coefficient_product(b[index] >> 2, dq[index]) for index in range(6))
    pole_prediction = (_coefficient_product(a[1] >> 2, sr[1])
                       + _coefficient_product(a[0] >> 2, sr[0]))
    return zero_prediction, pole_prediction


def _step(state: dict[str, object]) -> int:
    ap = int(state["ap"])
    yu = int(state["yu"])
    if ap >= 256:
        return yu
    y = int(state["yl"]) >> 6
    difference = yu - y
    weight = ap >> 2
    if difference > 0:
        y += (difference * weight) >> 6
    elif difference < 0:
        y += (difference * weight + 0x3F) >> 6
    return y


def _code_for_difference(difference: int, step: int) -> int:
    magnitude = abs(difference)
    exponent = _threshold_index(magnitude >> 1, _POWERS_OF_TWO)
    mantissa = ((magnitude << 7) >> exponent) & 0x7F
    normalized_log = ((exponent << 7) + mantissa) - (step >> 2)
    region = _threshold_index(normalized_log, _QUANT_THRESHOLDS)
    if difference < 0:
        return 15 - region
    return 15 if region == 0 else region


def _reconstructed_delta(sign: int, logarithm: int, step: int) -> int:
    adjusted = logarithm + (step >> 2)
    if adjusted < 0:
        return -32768 if sign else 0
    exponent = (adjusted >> 7) & 15
    mantissa = 128 + (adjusted & 127)
    value = (mantissa << 7) >> (14 - exponent)
    return value - 32768 if sign else value


def _refresh(signal_step: int, scale_delta: int, energy_code: int,
             delta: int, reconstructed: int, pole_error: int,
             state: dict[str, object]) -> None:
    a = state["a"]
    b = state["b"]
    pk = state["pk"]
    dq = state["dq"]
    sr = state["sr"]
    assert isinstance(a, list) and isinstance(b, list) and isinstance(pk, list)
    assert isinstance(dq, list) and isinstance(sr, list)

    magnitude = delta & 0x7FFF
    yl = int(state["yl"])
    ylint = yl >> 15
    yfrac = (yl >> 10) & 0x1F
    threshold = (32 + yfrac) << ylint
    if ylint > 9:
        threshold = 31 << 10
    delta_threshold = (threshold + (threshold >> 1)) >> 1
    transition = int(state["td"]) != 0 and magnitude > delta_threshold

    new_yu = _short(signal_step + ((scale_delta - signal_step) >> 5))
    new_yu = min(5120, max(544, new_yu))
    state["yu"] = new_yu
    state["yl"] = yl + new_yu + ((-yl) >> 6)

    if transition:
        a[:] = [0, 0]
        b[:] = [0] * 6
    else:
        pk0 = 1 if pole_error < 0 else 0
        sign_change = pk0 ^ pk[0]
        pole2 = a[1] - (a[1] >> 7)
        if pole_error != 0:
            pole1_update = a[0] if sign_change else -a[0]
            if pole1_update < -8191:
                pole2 -= 0x100
            elif pole1_update > 8191:
                pole2 += 0xFF
            else:
                pole2 += pole1_update >> 5
            if pk0 ^ pk[1]:
                if pole2 <= -12160:
                    pole2 = -12288
                elif pole2 >= 12416:
                    pole2 = 12288
                else:
                    pole2 -= 0x80
            elif pole2 <= -12416:
                pole2 = -12288
            elif pole2 >= 12160:
                pole2 = 12288
            else:
                pole2 += 0x80
        pole2 = _short(pole2)
        a[1] = pole2
        a[0] = _short(a[0] - (a[0] >> 8))
        if pole_error != 0:
            a[0] = _short(a[0] + (192 if sign_change == 0 else -192))
        limit = 15360 - pole2
        a[0] = _short(max(-limit, min(limit, a[0])))
        for index in range(6):
            b[index] = _short(b[index] - (b[index] >> 8))
            if delta & 0x7FFF:
                b[index] = _short(b[index] + (128 if (delta ^ dq[index]) >= 0 else -128))

    dq[1:] = dq[:-1]
    if magnitude == 0:
        dq[0] = 0x20 if delta >= 0 else _short(0xFC20)
    else:
        exponent = _threshold_index(magnitude, _POWERS_OF_TWO)
        encoded_delta = (exponent << 6) + ((magnitude << 6) >> exponent)
        dq[0] = _short(encoded_delta if delta >= 0 else encoded_delta - 0x400)

    sr[1] = sr[0]
    if reconstructed == 0:
        sr[0] = 0x20
    elif reconstructed > 0:
        exponent = _threshold_index(reconstructed, _POWERS_OF_TWO)
        sr[0] = _short((exponent << 6) + ((reconstructed << 6) >> exponent))
    elif reconstructed > -32768:
        absolute = -reconstructed
        exponent = _threshold_index(absolute, _POWERS_OF_TWO)
        sr[0] = _short((exponent << 6) + ((absolute << 6) >> exponent) - 0x400)
    else:
        sr[0] = _short(0xFC20)

    pk[1] = pk[0]
    pk[0] = 1 if pole_error < 0 else 0
    state["td"] = 0 if transition else (1 if a[1] < -11776 else 0)
    state["dms"] = _short(int(state["dms"]) + ((energy_code - int(state["dms"])) >> 5))
    state["dml"] = _short(int(state["dml"]) + (((energy_code << 2) - int(state["dml"])) >> 7))
    if transition:
        state["ap"] = 256
    elif signal_step < 1536 or int(state["td"]) == 1 or abs((int(state["dms"]) << 2) - int(state["dml"])) >= (int(state["dml"]) >> 3):
        state["ap"] = _short(int(state["ap"]) + ((0x200 - int(state["ap"])) >> 4))
    else:
        state["ap"] = _short(int(state["ap"]) + ((-int(state["ap"])) >> 4))


def _ulaw_to_linear(code: int) -> int:
    decoded = (~code) & 0xFF
    value = ((decoded & 0x0F) << 3) + 0x84
    value <<= (decoded & 0x70) >> 4
    return 0x84 - value if decoded & 0x80 else value - 0x84


def _encode_sample(code: int, state: dict[str, object]) -> int:
    sample = _ulaw_to_linear(code) >> 2
    zero_prediction, pole_prediction = _predict(state)
    sezi = _short(zero_prediction)
    sez = sezi >> 1
    estimate = _short((sezi + pole_prediction) >> 1)
    difference = _short(sample - estimate)
    step = _short(_step(state))
    adpcm_code = _code_for_difference(difference, step)
    delta = _short(_reconstructed_delta(adpcm_code & 8, _LOG_DELTA[adpcm_code], step))
    reconstructed = _short(estimate - (delta & 0x3FFF) if delta < 0 else estimate + delta)
    pole_error = _short(reconstructed + sez - estimate)
    _refresh(step, _SCALE_STEP[adpcm_code] << 5, _ENERGY_STEP[adpcm_code],
             delta, reconstructed, pole_error, state)
    return adpcm_code


def _encode(codes: Sequence[int]) -> bytes:
    state: dict[str, object] = {
        "yl": 34816, "yu": 544, "dms": 0, "dml": 0, "ap": 0,
        "a": [0, 0], "b": [0] * 6, "pk": [0, 0], "dq": [32] * 6,
        "sr": [32, 32], "td": 0,
    }
    packed = bytearray((len(codes) + 1) // 2)
    for position, code in enumerate(codes):
        nibble = _encode_sample(code, state)
        if position & 1:
            packed[position // 2] |= nibble << 4
        else:
            packed[position // 2] = nibble
    return bytes(packed)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 1
            or actual_length > MAX_INPUT_LENGTH or len(values) != actual_length):
        return INVALID_RESULT, b""
    count = values[0]
    if not 0 <= count <= MAX_SAMPLES or actual_length != count + 1:
        return INVALID_RESULT, b""
    if any(not 0 <= code <= 255 for code in values[1:]):
        return INVALID_RESULT, b""
    payload = _encode(values[1:])
    if not payload:
        return 0, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]


def generated_inputs() -> list[list[int]]:
    return [
        [0],
        [1, 255],
        [1, 247],
        [2, 255, 127],
        [8, 255, 254, 253, 252, 251, 250, 249, 248],
        [16, 0, 255, 15, 240, 127, 128, 85, 170, 1, 254, 16, 239, 64, 191, 32, 223],
    ]
