package mfcc

import "core:c"
import "core:math"

MAX_INPUT :: 2054
MAX_AUDIO :: 2048
MAX_FFT :: 1024
MAX_FRAMES :: 257
MAX_MELS :: 16
MAX_DCTS :: 40
PI :: 3.14159265358979323846264338327950288

fft :: proc "contextless" (real, imag: [^]f64, n: int) {
	reversed := 0
	for position := 1; position < n; position += 1 {
		bit := n >> 1
		for (reversed & bit) != 0 { reversed ^= bit; bit >>= 1 }
		reversed ^= bit
		if position < reversed {
			temporary := real[position]; real[position] = real[reversed]; real[reversed] = temporary
			temporary = imag[position]; imag[position] = imag[reversed]; imag[reversed] = temporary
		}
	}
	block_size := 2
	for block_size <= n {
		angle := -2.0 * PI / f64(block_size)
		step_real, step_imag := math.cos(angle), math.sin(angle)
		half := block_size >> 1
		for start := 0; start < n; start += block_size {
			weight_real, weight_imag := 1.0, 0.0
			for offset := 0; offset < half; offset += 1 {
				even, odd := start + offset, start + offset + half
				product_real := weight_real * real[odd] - weight_imag * imag[odd]
				product_imag := weight_real * imag[odd] + weight_imag * real[odd]
				real[odd] = real[even] - product_real
				imag[odd] = imag[even] - product_imag
				real[even] += product_real
				imag[even] += product_imag
				next_real := weight_real * step_real - weight_imag * step_imag
				weight_imag = weight_real * step_imag + weight_imag * step_real
				weight_real = next_real
			}
		}
		block_size *= 2
	}
}

hz_to_mel :: proc "contextless" (hz: f64) -> f64 { return 2595.0 * math.log10_f64(1.0 + hz / 700.0) }
mel_to_hz :: proc "contextless" (mel: f64) -> f64 { return 700.0 * (math.pow_f64(10.0, mel / 2595.0) - 1.0) }

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
mfcc :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_INPUT do return -1
	count_value, sample_rate_value, hop_ms_value := input[0], input[1], input[2]
	fft_value, mel_value, dct_value := input[3], input[4], input[5]
	if count_value < 33 || count_value > MAX_AUDIO || length != c.size_t(count_value + 6) do return -1
	if sample_rate_value < 8000 || sample_rate_value > 48000 || hop_ms_value < 1 || hop_ms_value > 50 do return -1
	if !(fft_value == 64 || fft_value == 128 || fft_value == 256 || fft_value == 512 || fft_value == 1024) do return -1
	if mel_value < 2 || mel_value > MAX_MELS || dct_value < 1 || dct_value > MAX_DCTS do return -1

	count, sample_rate := int(count_value), int(sample_rate_value)
	fft_size, mel_count, dct_count := int(fft_value), int(mel_value), int(dct_value)
	if count < fft_size / 2 + 1 do return -1
	hop_numerator := sample_rate * int(hop_ms_value)
	hop := hop_numerator / 1000
	hop_remainder := hop_numerator % 1000
	if hop_remainder > 500 || (hop_remainder == 500 && hop % 2 == 1) do hop += 1
	if hop < 1 do return -1

	var audio: [MAX_AUDIO]f64
	peak := 0.0
	for index := 0; index < count; index += 1 {
		sample := transmute(f64)input[6 + index]
		if sample != sample || math.abs(sample) > 1_000_000.0 do return -1
		audio[index] = sample
		if math.abs(sample) > peak do peak = math.abs(sample)
	}
	if peak == 0.0 do return -1
	for index := 0; index < count; index += 1 { audio[index] /= peak }

	pad := fft_size / 2
	frames := count / hop + 1
	bin_count := fft_size / 2 + 1
	if frames > MAX_FRAMES do return -1
	var padded: [MAX_AUDIO + MAX_FFT]f64
	for index := 0; index < pad; index += 1 { padded[index] = audio[pad - index] }
	for index := 0; index < count; index += 1 { padded[pad + index] = audio[index] }
	for index := 0; index < pad; index += 1 { padded[pad + count + index] = audio[count - 2 - index] }

	var frequencies: [MAX_MELS + 2]f64
	var bins: [MAX_MELS + 2]int
	mel_low, mel_high := hz_to_mel(0.0), hz_to_mel(f64(sample_rate / 2))
	for index := 0; index < mel_count + 2; index += 1 {
		mel := mel_low + (mel_high - mel_low) * f64(index) / f64(mel_count + 1)
		frequencies[index] = mel_to_hz(mel)
		bin := math.floor_f64(f64(fft_size + 1) / f64(sample_rate) * frequencies[index])
		if bin < 0.0 || bin >= f64(bin_count) do return -1
		bins[index] = int(bin)
	}
	for index := 0; index < mel_count + 1; index += 1 { if bins[index] >= bins[index + 1] do return -1 }
	var norms: [MAX_MELS]f64
	for index := 0; index < mel_count; index += 1 {
		norms[index] = 2.0 / (frequencies[index + 2] - frequencies[index])
		if norms[index] != norms[index] do return -1
	}

	var window: [MAX_FFT]f64
	for index := 0; index < fft_size; index += 1 { window[index] = 0.5 - 0.5 * math.cos(2.0 * PI * f64(index) / f64(fft_size)) }
	var logged: [MAX_MELS][MAX_FRAMES]f64
	for frame := 0; frame < frames; frame += 1 {
		var real, imag: [MAX_FFT]f64
		for index := 0; index < fft_size; index += 1 {
			real[index] = padded[frame * hop + index] * window[index]
			imag[index] = 0.0
		}
		fft(&real[0], &imag[0], fft_size)
		var power: [MAX_FFT / 2 + 1]f32
		for index := 0; index < bin_count; index += 1 {
			real32, imag32 := f32(real[index]), f32(imag[index])
			magnitude := f32(math.sqrt_f64(f64(real32 * real32 + imag32 * imag32)))
			power[index] = magnitude * magnitude
		}
		for filter_index := 0; filter_index < mel_count; filter_index += 1 {
			first, middle, last := bins[filter_index], bins[filter_index + 1], bins[filter_index + 2]
			rise, fall := middle - first, last - middle
			energy := 0.0
			for index := first; index < middle; index += 1 {
				weight := f64(0.0)
				if rise != 1 do weight = f64(index - first) / f64(rise - 1)
				energy += f64(power[index]) * weight
			}
			for index := middle; index < last; index += 1 {
				weight := f64(1.0)
				if fall != 1 do weight = 1.0 - f64(index - middle) / f64(fall - 1)
				energy += f64(power[index]) * weight
			}
			energy *= norms[filter_index]
			if energy <= 0.0 || energy != energy do return -1
			logged[filter_index][frame] = 10.0 * math.log10_f64(energy)
		}
	}

	var result: [MAX_DCTS][MAX_FRAMES]f64
	for coefficient := 0; coefficient < dct_count; coefficient += 1 {
		scale := math.sqrt_f64(2.0 / f64(mel_count))
		if coefficient == 0 do scale = 1.0 / math.sqrt_f64(f64(mel_count))
		for frame := 0; frame < frames; frame += 1 {
			total := 0.0
			for index := 0; index < mel_count; index += 1 {
				basis := scale * math.cos(f64(coefficient) * (2.0 * f64(index) + 1.0) * PI / (2.0 * f64(mel_count)))
				if coefficient == 0 do basis = scale
				total += basis * logged[index][frame]
			}
			if total != total do return -1
			result[coefficient][frame] = total
		}
	}

	required := dct_count * frames * 8
	if output == nil || capacity < c.size_t(required) do return -2
	for coefficient := 0; coefficient < dct_count; coefficient += 1 {
		for frame := 0; frame < frames; frame += 1 { put_f64_le(output, (coefficient * frames + frame) * 8, result[coefficient][frame]) }
	}
	return i64(required)
}
