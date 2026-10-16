package chaos_machine

import "core:c"
import "core:math"

fraction_one :: proc "contextless" (value: f64) -> f64 { return value - math.floor_f64(value) }
round_ten :: proc "contextless" (value: f64) -> f64 {
	bits := transmute(u64)value
	exponent := (bits >> 52) & 0x7ff
	if exponent == 0 do return 0.0
	mantissa := (u64(1) << 52) | (bits & ((u64(1) << 52) - 1))
	low_product := (mantissa & 0xffffffff) * 9765625
	high_product := (mantissa >> 32) * 9765625
	shifted_high := high_product << 32
	low := shifted_high + low_product
	carry: u64 = 0
	if low < shifted_high do carry = 1
	high := (high_product >> 32) + carry
	shift := 1065 - i64(exponent)
	if shift > 77 do return 0.0
	rounded: u64 = 0
	relation: i64 = 0
	if shift < 64 {
		rounded = (high << u64(64 - shift)) | (low >> u64(shift))
		remainder := low & ((u64(1) << u64(shift)) - 1)
		half := u64(1) << u64(shift - 1)
		if remainder > half do relation = 1
		if remainder < half do relation = -1
	} else if shift == 64 {
		rounded = high
		half := u64(1) << 63
		if low > half do relation = 1
		if low < half do relation = -1
	} else {
		upper_bits := u64(shift - 64)
		rounded = high >> upper_bits
		remainder_high := high & ((u64(1) << upper_bits) - 1)
		half_high := u64(1) << (upper_bits - 1)
		if remainder_high > half_high || (remainder_high == half_high && low != 0) do relation = 1
		if remainder_high < half_high do relation = -1
	}
	if relation > 0 || (relation == 0 && (rounded & 1) != 0) do rounded += 1
	return f64(rounded) / 10000000000.0
}
pull :: proc "contextless" (machine_time: ^u64, buffer: ^[5]f64, params: ^[5]f64) -> u32 {
	key := int(machine_time^ % 5)
	for _ in 0..<3 {
		rate, value := params[key], buffer[key]
		buffer[key] = round_ten(rate * value * (1.0 - value))
		params[key] = fraction_one(f64(machine_time^) * 0.01 + rate * 1.01) + 3.0
	}
	x := u64(buffer[(key + 2) % 5] * 10000000000.0)
	y := u64(buffer[(key + 3) % 5] * 10000000000.0)
	machine_time^ += 1
	x ~= y >> 13; y ~= x << 17; x ~= y >> 5
	return u32(x & 0xFFFFFFFF)
}
@(export)
chaos_machine :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 66 do return -1
	if values[0] < 0 || values[0] > 64 || length != c.size_t(values[0] + 2) do return -1
	seed_count := int(values[0])
	pull_input := values[int(length) - 1]
	if pull_input < 0 || pull_input > 64 do return -1
	for index in 0..<seed_count {
		if values[index + 1] < 0 || values[index + 1] > 1000000 do return -1
	}
	required := 4 * int(pull_input)
	if c.size_t(required) > output_capacity || (required != 0 && output == nil) do return -2
	buffer := [5]f64{0.33, 0.44, 0.55, 0.44, 0.33}
	params: [5]f64
	machine_time: u64 = 0
	for seed_index in 0..<seed_count {
		seed := f64(values[seed_index + 1])
		for key in 0..<5 {
			if buffer[key] == 0.0 do return -1
			evolution := seed / buffer[key]
			value := fraction_one(buffer[(key + 1) % 5] + evolution)
			rate := fraction_one(params[key] + evolution) + 3.0
			buffer[key] = round_ten(rate * value * (1.0 - value))
			params[key] = rate
		}
		machine_time += 1
	}
	for index in 0..<int(pull_input) {
		result := pull(&machine_time, &buffer, &params)
		for byte in 0..<4 { output[4 * index + byte] = u8((result >> u64(8 * byte)) & 255) }
	}
	return i64(required)
}
