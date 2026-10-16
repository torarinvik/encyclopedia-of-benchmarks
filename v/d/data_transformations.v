module data_transformations

import math

const max_sample_count = 128

fn round_three_decimals(value f64) f64 {
	bits := math.bits_from_f64(value)
	negative := (bits >> 63) != 0
	exponent := int((bits >> 52) & 0x7ff)
	fraction := bits & ((u64(1) << 52) - 1)
	significand := if exponent == 0 { fraction } else { fraction | (u64(1) << 52) }
	exponent2 := if exponent == 0 { -1074 } else { exponent - 1023 - 52 }
	scaled := significand * 1000
	mut rounded := u64(0)
	if exponent2 >= 0 {
		rounded = scaled << u32(exponent2)
	} else {
		shift := -exponent2
		if shift < 64 {
			rounded = scaled >> u32(shift)
			if shift > 0 {
				remainder := scaled & ((u64(1) << u32(shift)) - 1)
				half := u64(1) << u32(shift - 1)
				if remainder > half || (remainder == half && (rounded & 1) != 0) { rounded++ }
			}
		}
	}
	result := f64(rounded) / 1000.0
	return if negative { -result } else { result }
}

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'data_transformations']
pub fn data_transformations(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length < 4 || length > usize(max_sample_count + 2) { return -1 }
	unsafe {
		mode := values[0]
		count_arg := values[1]
		if (mode != 0 && mode != 1) || count_arg < 2 || count_arg > max_sample_count ||
			length != usize(count_arg + 2) { return -1 }
		count := int(count_arg)
		mut minimum := values[2]
		mut maximum := values[2]
		mut sum := i64(0)
		mut sum_squares := i64(0)
		for index in 0 .. count {
			value := values[index + 2]
			if value < -100000 || value > 100000 { return -1 }
			if value < minimum { minimum = value }
			if value > maximum { maximum = value }
			sum += value
			sum_squares += value * value
		}
		if minimum == maximum { return -1 }
		output_bytes := usize(count * 8)
		if output == nil || capacity < output_bytes { return -2 }
		if mode == 0 {
			span := f64(maximum - minimum)
			for index in 0 .. count {
				normalized := f64(values[index + 2] - minimum) / span
				put_f64_le(mut output, index * 8, round_three_decimals(normalized))
			}
		} else {
			average := f64(sum) / f64(count)
			variance_numerator := i64(count) * sum_squares - sum * sum
			variance_denominator := f64(count * (count - 1))
			deviation := math.sqrt(f64(variance_numerator) / variance_denominator)
			for index in 0 .. count {
				standardized := (f64(values[index + 2]) - average) / deviation
				put_f64_le(mut output, index * 8, round_three_decimals(standardized))
			}
		}
		return i64(output_bytes)
	}
}
