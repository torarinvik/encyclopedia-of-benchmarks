"""Bounded, independent MFCC oracle for the i64-array byte-output ABI."""
from __future__ import annotations

import math
import struct

MIN_SAMPLES = 33
MAX_SAMPLES = 2048
MAX_PARSEABLE_INPUT_LENGTH = 2054
MAX_FRAMES = 257
MAX_OUTPUT_BYTES = 82_240
FFT_SIZES = (64, 128, 256, 512, 1024)
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
PI = math.pi


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _fft(real: list[float], imag: list[float]) -> None:
    """In-place radix-2 forward FFT."""
    size = len(real)
    j = 0
    for i in range(1, size):
        bit = size >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            real[i], real[j] = real[j], real[i]
            imag[i], imag[j] = imag[j], imag[i]
    length = 2
    while length <= size:
        angle = -2.0 * PI / length
        step_r, step_i = math.cos(angle), math.sin(angle)
        half = length // 2
        for start in range(0, size, length):
            wr, wi = 1.0, 0.0
            for offset in range(half):
                even = start + offset
                odd = even + half
                tr = wr * real[odd] - wi * imag[odd]
                ti = wr * imag[odd] + wi * real[odd]
                real[odd] = real[even] - tr
                imag[odd] = imag[even] - ti
                real[even] += tr
                imag[even] += ti
                wr, wi = wr * step_r - wi * step_i, wr * step_i + wi * step_r
        length <<= 1


def _decode(values: list[int] | tuple[int, ...]) -> tuple[list[float], int, int, int, int, int] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 6
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count, sample_rate, hop_ms, fft_size, mel_count, dct_count = values[:6]
    if not MIN_SAMPLES <= count <= MAX_SAMPLES or len(values) != count + 6:
        return None
    if not 8000 <= sample_rate <= 48000 or not 1 <= hop_ms <= 50:
        return None
    if fft_size not in FFT_SIZES or not 2 <= mel_count <= 16 or not 1 <= dct_count <= 40:
        return None
    if count < fft_size // 2 + 1:
        return None
    hop = round(sample_rate * hop_ms / 1000)
    if hop < 1:
        return None
    audio: list[float] = []
    max_abs = 0.0
    for bits in values[6:]:
        sample = struct.unpack("<d", (bits & ((1 << 64) - 1)).to_bytes(8, "little"))[0]
        if not math.isfinite(sample) or abs(sample) > 1_000_000.0:
            return None
        audio.append(sample)
        max_abs = max(max_abs, abs(sample))
    if max_abs == 0.0:
        return None
    return [sample / max_abs for sample in audio], sample_rate, hop, fft_size, mel_count, dct_count


def mfcc_values(values: list[int] | tuple[int, ...]) -> tuple[int, int, int, list[float]]:
    """Return (status, rows, columns, row-major values); invalid inputs use -1."""
    parsed = _decode(values)
    if parsed is None:
        return INVALID_RESULT, 0, 0, []
    audio, sample_rate, hop, fft_size, mel_count, dct_count = parsed
    count = len(audio)
    frames = count // hop + 1
    if frames > MAX_FRAMES:
        return INVALID_RESULT, 0, 0, []

    # Reflect padding excludes the boundary sample, matching numpy.pad(mode="reflect").
    padded = [audio[i] for i in range(fft_size // 2, 0, -1)]
    padded.extend(audio)
    padded.extend(audio[count - 2 - i] for i in range(fft_size // 2))
    window = [0.5 - 0.5 * math.cos(2.0 * PI * i / fft_size) for i in range(fft_size)]

    mel_min = 0.0
    mel_max = 2595.0 * math.log10(1.0 + (sample_rate // 2) / 700.0)
    mel_points = [mel_min + (mel_max - mel_min) * i / (mel_count + 1)
                  for i in range(mel_count + 2)]
    freqs = [700.0 * (10.0 ** (point / 2595.0) - 1.0) for point in mel_points]
    bins = [math.floor((fft_size + 1) / sample_rate * freq) for freq in freqs]
    if any(bins[i] >= bins[i + 1] for i in range(len(bins) - 1)):
        return INVALID_RESULT, 0, 0, []
    spectrum_size = fft_size // 2 + 1
    if bins[0] < 0 or bins[-1] >= spectrum_size:
        return INVALID_RESULT, 0, 0, []

    filters: list[list[float]] = []
    norms: list[float] = []
    for i in range(mel_count):
        start, middle, end = bins[i:i + 3]
        weights = [0.0] * spectrum_size
        rising_count = middle - start
        falling_count = end - middle
        for k in range(start, middle):
            weights[k] = 0.0 if rising_count == 1 else (k - start) / (rising_count - 1)
        for k in range(middle, end):
            weights[k] = 1.0 if falling_count == 1 else 1.0 - (k - middle) / (falling_count - 1)
        filters.append(weights)
        norms.append(2.0 / (freqs[i + 2] - freqs[i]))

    logged: list[list[float]] = [[0.0] * frames for _ in range(mel_count)]
    for frame in range(frames):
        real = [padded[frame * hop + i] * window[i] for i in range(fft_size)]
        imag = [0.0] * fft_size
        _fft(real, imag)
        power: list[float] = []
        for k in range(spectrum_size):
            # The source stores the FFT as complex64, then abs and square as float32.
            re32, im32 = _f32(real[k]), _f32(imag[k])
            magnitude = _f32(math.sqrt(_f32(_f32(re32 * re32) + _f32(im32 * im32))))
            power.append(_f32(magnitude * magnitude))
        for filter_index, weights in enumerate(filters):
            energy = sum(float(power[k]) * weights[k] for k in range(spectrum_size)) * norms[filter_index]
            if not math.isfinite(energy) or energy <= 0.0:
                return INVALID_RESULT, 0, 0, []
            logged[filter_index][frame] = 10.0 * math.log10(energy)

    result: list[float] = []
    for dct_index in range(dct_count):
        scale = 1.0 / math.sqrt(mel_count) if dct_index == 0 else math.sqrt(2.0 / mel_count)
        for frame in range(frames):
            total = 0.0
            for j in range(mel_count):
                basis = scale if dct_index == 0 else scale * math.cos(
                    dct_index * (2 * j + 1) * PI / (2.0 * mel_count))
                total += basis * logged[j][frame]
            if not math.isfinite(total):
                return INVALID_RESULT, 0, 0, []
            result.append(total)
    return len(result) * 8, dct_count, frames, result


def expected_output(values: list[int] | tuple[int, ...], output_capacity: int | None = None) -> tuple[int, bytes]:
    status, _rows, _columns, result = mfcc_values(values)
    if status < 0:
        return status, b""
    encoded = b"".join(struct.pack("<d", value) for value in result)
    if output_capacity is not None and output_capacity < len(encoded):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(encoded), encoded
