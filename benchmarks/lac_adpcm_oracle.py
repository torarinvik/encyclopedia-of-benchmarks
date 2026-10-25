"""Independent reference for the bounded IMA/DVI ADPCM encoder and decoder."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_ENCODE_SAMPLES = 256
MAX_DECODE_BYTES = 128
MAX_INPUT_LENGTH = MAX_ENCODE_SAMPLES + 2
MAX_OUTPUT_BYTES = 512
INDEX_ADJUST = (-1, -1, -1, -1, 2, 4, 6, 8,
                -1, -1, -1, -1, 2, 4, 6, 8)
STEP_SIZES = (
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
    34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130,
    143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449,
    494, 544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411,
    1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026,
    4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487,
    12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794,
    32767,
)


def _encode_one(sample: int, predictor: int, index: int) -> tuple[int, int, int]:
    step = STEP_SIZES[index]
    difference = sample - predictor
    sign = 8 if difference < 0 else 0
    if sign:
        difference = -difference

    code = 0
    reconstructed_delta = step >> 3
    if difference >= step:
        code |= 4
        difference -= step
        reconstructed_delta += step
    step >>= 1
    if difference >= step:
        code |= 2
        difference -= step
        reconstructed_delta += step
    step >>= 1
    if difference >= step:
        code |= 1
        reconstructed_delta += step

    predictor += -reconstructed_delta if sign else reconstructed_delta
    predictor = min(32767, max(-32768, predictor))
    code |= sign
    index = min(88, max(0, index + INDEX_ADJUST[code]))
    return code, predictor, index


def _decode_one(code: int, predictor: int, index: int) -> tuple[int, int]:
    step = STEP_SIZES[index]
    index = min(88, max(0, index + INDEX_ADJUST[code]))
    magnitude = code & 7
    reconstructed_delta = step >> 3
    if magnitude & 4:
        reconstructed_delta += step
    if magnitude & 2:
        reconstructed_delta += step >> 1
    if magnitude & 1:
        reconstructed_delta += step >> 2
    predictor += -reconstructed_delta if code & 8 else reconstructed_delta
    predictor = min(32767, max(-32768, predictor))
    return predictor, index


def _encode(samples: Sequence[int]) -> bytes:
    predictor = 0
    index = 0
    packed = bytearray((len(samples) + 1) // 2)
    for position, sample in enumerate(samples):
        code, predictor, index = _encode_one(sample, predictor, index)
        if position & 1:
            packed[position // 2] |= code
        else:
            packed[position // 2] = code << 4
    return bytes(packed)


def _decode(packed: Sequence[int]) -> bytes:
    predictor = 0
    index = 0
    output = bytearray()
    for byte in packed:
        for code in (byte >> 4, byte & 15):
            predictor, index = _decode_one(code, predictor, index)
            output.extend(predictor.to_bytes(2, "little", signed=True))
    return bytes(output)


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
    if (type(actual_length) is not int or actual_length < 2
            or actual_length > MAX_INPUT_LENGTH or len(values) != actual_length):
        return INVALID_RESULT, b""

    mode, count = values[:2]
    if mode == 1:
        if not 0 <= count <= MAX_ENCODE_SAMPLES or actual_length != count + 2:
            return INVALID_RESULT, b""
        if any(not -32768 <= value <= 32767 for value in values[2:]):
            return INVALID_RESULT, b""
        payload = _encode(values[2:])
    elif mode == 2:
        if not 0 <= count <= MAX_DECODE_BYTES or actual_length != count + 2:
            return INVALID_RESULT, b""
        if any(not 0 <= value <= 255 for value in values[2:]):
            return INVALID_RESULT, b""
        payload = _decode(values[2:])
    else:
        return INVALID_RESULT, b""

    if not payload:
        return 0, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
