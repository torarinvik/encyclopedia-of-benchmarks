package data_transformations

import "core:c"
import "core:math"

Max_Sample_Count :: 128

round_three_decimals :: proc "contextless" (value: f64) -> f64 {
	bits := transmute(u64)value
	negative := (bits >> 63) != 0
	exponent := (bits >> 52) & 0x7ff
	fraction := bits & ((u64(1) << 52) - 1)
	significand := fraction
	if exponent != 0 do significand |= u64(1) << 52
	exponent2: i64 = -1074
	if exponent != 0 do exponent2 = i64(exponent) - 1023 - 52
	scaled := significand * 1000
	rounded: u64 = 0
	if exponent2 >= 0 {
		rounded = scaled << u64(exponent2)
	} else {
		shift := u64(-exponent2)
		if shift < 64 {
			rounded = scaled >> shift
			if shift > 0 {
				remainder := scaled & ((u64(1) << shift) - 1)
				half := u64(1) << (shift - 1)
				if remainder > half || (remainder == half && (rounded & 1) != 0) do rounded += 1
			}
		}
	}
	result := f64(rounded) / 1000.0
	if negative do return -result
	return result
}

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
data_transformations :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 4 || length > c.size_t(Max_Sample_Count + 2) do return -1
	mode := values[0]
	count_arg := values[1]
	if (mode != 0 && mode != 1) || count_arg < 2 || count_arg > Max_Sample_Count ||
		length != c.size_t(count_arg + 2) do return -1
	count := int(count_arg)
	minimum := values[2]
	maximum := values[2]
	sum: i64 = 0
	sum_squares: i64 = 0
	for index := 0; index < count; index += 1 {
		value := values[index + 2]
		if value < -100000 || value > 100000 do return -1
		if value < minimum do minimum = value
		if value > maximum do maximum = value
		sum += value
		sum_squares += value * value
	}
	if minimum == maximum do return -1
	output_bytes := c.size_t(count * 8)
	if output == nil || capacity < output_bytes do return -2
	if mode == 0 {
		span := f64(maximum - minimum)
		for index := 0; index < count; index += 1 {
			normalized := f64(values[index + 2] - minimum) / span
			put_f64_le(output, index * 8, round_three_decimals(normalized))
		}
	} else {
		average := f64(sum) / f64(count)
		variance_numerator := i64(count) * sum_squares - sum * sum
		variance_denominator := f64(count * (count - 1))
		deviation := math.sqrt(f64(variance_numerator) / variance_denominator)
		for index := 0; index < count; index += 1 {
			standardized := (f64(values[index + 2]) - average) / deviation
			put_f64_le(output, index * 8, round_three_decimals(standardized))
		}
	}
	return i64(output_bytes)
}
