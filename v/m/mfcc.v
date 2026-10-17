module mfcc

import math

const max_input = 2054
const max_audio = 2048
const max_fft = 1024
const max_frames = 257
const max_mels = 16
const max_dcts = 40
const pi = 3.14159265358979323846264338327950288

fn fft(mut real []f64, mut imag []f64) {
	n := real.len
	mut reversed := 0
	for position in 1 .. n {
		mut bit := n >> 1
		for (reversed & bit) != 0 {
			reversed ^= bit
			bit >>= 1
		}
		reversed ^= bit
		if position < reversed {
			real[position], real[reversed] = real[reversed], real[position]
			imag[position], imag[reversed] = imag[reversed], imag[position]
		}
	}
	mut block_size := 2
	for block_size <= n {
		angle := -2.0 * pi / f64(block_size)
		step_real, step_imag := math.cos(angle), math.sin(angle)
		half := block_size >> 1
		mut start := 0
		for start < n {
			mut weight_real, mut weight_imag := 1.0, 0.0
			for offset in 0 .. half {
				even, odd := start + offset, start + offset + half
				product_real := weight_real * real[odd] - weight_imag * imag[odd]
				product_imag := weight_real * imag[odd] + weight_imag * real[odd]
				real[odd], imag[odd] = real[even] - product_real, imag[even] - product_imag
				real[even], imag[even] = real[even] + product_real, imag[even] + product_imag
				next_real := weight_real * step_real - weight_imag * step_imag
				weight_imag = weight_real * step_imag + weight_imag * step_real
				weight_real = next_real
			}
			start += block_size
		}
		block_size *= 2
	}
}

fn hz_to_mel(hz f64) f64 { return 2595.0 * math.log10(1.0 + hz / 700.0) }
fn mel_to_hz(mel f64) f64 { return 700.0 * (math.pow(10.0, mel / 2595.0) - 1.0) }

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'mfcc']
pub fn mfcc(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input { return -1 }
	unsafe {
		count_value, sample_rate_value, hop_ms_value := input[0], input[1], input[2]
		fft_value, mel_value, dct_value := input[3], input[4], input[5]
		if count_value < 33 || count_value > max_audio || length != usize(count_value + 6) { return -1 }
		if sample_rate_value < 8000 || sample_rate_value > 48000 || hop_ms_value < 1 || hop_ms_value > 50 { return -1 }
		if fft_value != 64 && fft_value != 128 && fft_value != 256 && fft_value != 512 && fft_value != 1024 { return -1 }
		if mel_value < 2 || mel_value > max_mels || dct_value < 1 || dct_value > max_dcts { return -1 }

		count, sample_rate := int(count_value), int(sample_rate_value)
		fft_size, mel_count, dct_count := int(fft_value), int(mel_value), int(dct_value)
		if count < fft_size / 2 + 1 { return -1 }
		hop_numerator := sample_rate * int(hop_ms_value)
		mut hop := hop_numerator / 1000
		hop_remainder := hop_numerator % 1000
		if hop_remainder > 500 || (hop_remainder == 500 && hop % 2 == 1) { hop++ }
		if hop < 1 { return -1 }

		mut audio := [max_audio]f64{}
		mut peak := 0.0
		for index in 0 .. count {
			sample := math.f64_from_bits(u64(input[6 + index]))
			if sample != sample || math.abs(sample) > 1_000_000.0 { return -1 }
			audio[index] = sample
			if math.abs(sample) > peak { peak = math.abs(sample) }
		}
		if peak == 0.0 { return -1 }
		for index in 0 .. count { audio[index] /= peak }

		pad := fft_size / 2
		frames := count / hop + 1
		bin_count := fft_size / 2 + 1
		if frames > max_frames { return -1 }
		mut padded := [max_audio + max_fft]f64{}
		for index in 0 .. pad { padded[index] = audio[pad - index] }
		for index in 0 .. count { padded[pad + index] = audio[index] }
		for index in 0 .. pad { padded[pad + count + index] = audio[count - 2 - index] }

		mut frequencies := [max_mels + 2]f64{}
		mut bins := [max_mels + 2]int{}
		mel_low, mel_high := hz_to_mel(0.0), hz_to_mel(f64(sample_rate / 2))
		for index in 0 .. mel_count + 2 {
			mel := mel_low + (mel_high - mel_low) * f64(index) / f64(mel_count + 1)
			frequencies[index] = mel_to_hz(mel)
			bin := math.floor(f64(fft_size + 1) / f64(sample_rate) * frequencies[index])
			if bin < 0.0 || bin >= f64(bin_count) { return -1 }
			bins[index] = int(bin)
		}
		for index in 0 .. mel_count + 1 { if bins[index] >= bins[index + 1] { return -1 } }
		mut norms := [max_mels]f64{}
		for index in 0 .. mel_count {
			norms[index] = 2.0 / (frequencies[index + 2] - frequencies[index])
			if norms[index] != norms[index] { return -1 }
		}

		mut window := [max_fft]f64{}
		for index in 0 .. fft_size { window[index] = 0.5 - 0.5 * math.cos(2.0 * pi * f64(index) / f64(fft_size)) }
		mut logged := [max_mels][max_frames]f64{}
		for frame in 0 .. frames {
			mut real := []f64{len: fft_size, init: 0.0}
			mut imag := []f64{len: fft_size, init: 0.0}
			for index in 0 .. fft_size { real[index] = padded[frame * hop + index] * window[index] }
			fft(mut real, mut imag)
			mut power := [max_fft / 2 + 1]f32{}
			for index in 0 .. bin_count {
				r, q := f32(real[index]), f32(imag[index])
				magnitude := f32(math.sqrt(f64(r * r + q * q)))
				power[index] = magnitude * magnitude
			}
			for filter_index in 0 .. mel_count {
				first, middle, last := bins[filter_index], bins[filter_index + 1], bins[filter_index + 2]
				rise, fall := middle - first, last - middle
				mut energy := 0.0
				for index in first .. middle {
					weight := if rise == 1 { 0.0 } else { f64(index - first) / f64(rise - 1) }
					energy += f64(power[index]) * weight
				}
				for index in middle .. last {
					weight := if fall == 1 { 1.0 } else { 1.0 - f64(index - middle) / f64(fall - 1) }
					energy += f64(power[index]) * weight
				}
				energy *= norms[filter_index]
				if energy <= 0.0 || energy != energy { return -1 }
				logged[filter_index][frame] = 10.0 * math.log10(energy)
			}
		}

		mut result := [max_dcts][max_frames]f64{}
		for coefficient in 0 .. dct_count {
			scale := if coefficient == 0 { 1.0 / math.sqrt(f64(mel_count)) } else { math.sqrt(2.0 / f64(mel_count)) }
			for frame in 0 .. frames {
				mut total := 0.0
				for index in 0 .. mel_count {
					basis := if coefficient == 0 { scale } else {
						scale * math.cos(f64(coefficient) * (2.0 * f64(index) + 1.0) * pi / (2.0 * f64(mel_count)))
					}
					total += basis * logged[index][frame]
				}
				if total != total { return -1 }
				result[coefficient][frame] = total
			}
		}

		required := dct_count * frames * 8
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		for coefficient in 0 .. dct_count {
			for frame in 0 .. frames { put_f64_le(mut output, (coefficient * frames + frame) * 8, result[coefficient][frame]) }
		}
		return i64(required)
	}
}
