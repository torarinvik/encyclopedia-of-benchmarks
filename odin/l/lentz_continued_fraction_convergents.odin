package lentz_continued_fraction_convergents

import "core:c"

MAX_TERMS :: 8
MAX_INPUT_LENGTH :: 19
MODULUS :: i64(998244353)

normalize :: proc "contextless" (value_input: i64) -> i64 {
	value := value_input % MODULUS
	if value < 0 { value += MODULUS }
	return value
}

power :: proc "contextless" (base_input, exponent_input: i64) -> i64 {
	base, exponent, result := normalize(base_input), exponent_input, i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % MODULUS }
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
lentz_continued_fraction_convergents :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) { return -1 }
	count_value := input[0]
	if count_value < 1 || count_value > i64(MAX_TERMS) { return -1 }
	count := int(count_value)
	if length != c.size_t(2+2*count) { return -1 }
	for i := 1; i < int(length); i += 1 {
		if input[i] < 0 || input[i] >= MODULUS { return -1 }
	}
	value := input[1]
	if value == 0 { return -1 }
	c_ratio, d_ratio := value, i64(0)
	trace: [MAX_TERMS+2]i64
	trace[0] = value
	for index := 0; index < count; index += 1 {
		numerator, denominator := input[2+2*index], input[3+2*index]
		d_denominator := normalize(denominator+numerator*d_ratio)
		if d_denominator == 0 || c_ratio == 0 { return -1 }
		c_value := normalize(denominator+numerator*power(c_ratio, MODULUS-2))
		if c_value == 0 { return -1 }
		d_ratio = power(d_denominator, MODULUS-2)
		value = value*c_value%MODULUS*d_ratio%MODULUS
		c_ratio = c_value
		trace[index+1] = value
	}
	output_bytes := 8*(count+2)
	if output == nil || capacity < c.size_t(output_bytes) { return -2 }
	store_i64_le(output, 0, i64(count+1))
	for i := 0; i <= count; i += 1 { store_i64_le(output, 8*(i+1), trace[i]) }
	return i64(output_bytes)
}
