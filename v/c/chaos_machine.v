module chaos_machine

import math

fn fraction_one(value f64) f64 { return value - math.floor(value) }
fn round_ten(value f64) f64 {
	bits := math.f64_bits(value)
	exponent := (bits >> 52) & 0x7ff
	if exponent == 0 { return 0.0 }
	mantissa := (u64(1) << 52) | (bits & ((u64(1) << 52) - 1))
	low_product := (mantissa & 0xffffffff) * 9765625
	high_product := (mantissa >> 32) * 9765625
	shifted_high := high_product << 32
	low := shifted_high + low_product
	mut carry := u64(0)
	if low < shifted_high { carry = 1 }
	high := (high_product >> 32) + carry
	shift := 1065 - int(exponent)
	if shift > 77 { return 0.0 }
	mut rounded := u64(0)
	mut relation := 0
	if shift < 64 {
		rounded = (high << u32(64 - shift)) | (low >> u32(shift))
		remainder := low & ((u64(1) << u32(shift)) - 1)
		half := u64(1) << u32(shift - 1)
		if remainder > half { relation = 1 }
		if remainder < half { relation = -1 }
	} else if shift == 64 {
		rounded = high
		half := u64(1) << 63
		if low > half { relation = 1 }
		if low < half { relation = -1 }
	} else {
		upper_bits := u32(shift - 64)
		rounded = high >> upper_bits
		remainder_high := high & ((u64(1) << upper_bits) - 1)
		half_high := u64(1) << (upper_bits - 1)
		if remainder_high > half_high || (remainder_high == half_high && low != 0) { relation = 1 }
		if remainder_high < half_high { relation = -1 }
	}
	if relation > 0 || (relation == 0 && (rounded & 1) != 0) { rounded++ }
	return f64(rounded) / 10000000000.0
}
fn pull(mut machine_time [1]u64, mut buffer [5]f64, mut params [5]f64) u32 {
	key := int(machine_time[0] % 5)
	for _ in 0 .. 3 {
		rate := params[key]
		value := buffer[key]
		buffer[key] = round_ten(rate * value * (1.0 - value))
		params[key] = fraction_one(f64(machine_time[0]) * 0.01 + rate * 1.01) + 3.0
	}
	mut x := u64(buffer[(key + 2) % 5] * 10000000000.0)
	mut y := u64(buffer[(key + 3) % 5] * 10000000000.0)
	machine_time[0]++
	x ^= y >> 13
	y ^= x << 17
	x ^= y >> 5
	return u32(x & 0xFFFFFFFF)
}
@[export: 'chaos_machine']
pub fn chaos_machine(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > 66 { return -1 }
	seed_count_input := unsafe { values[0] }
	if seed_count_input < 0 || seed_count_input > 64 || length != usize(seed_count_input + 2) { return -1 }
	seed_count := int(seed_count_input)
	pull_input := unsafe { values[length - 1] }
	if pull_input < 0 || pull_input > 64 { return -1 }
	for index in 0 .. seed_count {
		seed := unsafe { values[index + 1] }
		if seed < 0 || seed > 1000000 { return -1 }
	}
	required := int(4 * pull_input)
	if usize(required) > output_capacity { return -2 }
	mut buffer := [5]f64{init: 0.0}
	buffer[0] = 0.33
	buffer[1] = 0.44
	buffer[2] = 0.55
	buffer[3] = 0.44
	buffer[4] = 0.33
	mut params := [5]f64{}
	mut machine_time := [1]u64{init: 0}
	for seed_index in 0 .. seed_count {
		seed := f64(unsafe { values[seed_index + 1] })
		for key in 0 .. 5 {
			if buffer[key] == 0.0 { return -1 }
			evolution := seed / buffer[key]
			value := fraction_one(buffer[(key + 1) % 5] + evolution)
			rate := fraction_one(params[key] + evolution) + 3.0
			buffer[key] = round_ten(rate * value * (1.0 - value))
			params[key] = rate
		}
		machine_time[0]++
	}
	unsafe {
		for index in 0 .. int(pull_input) {
			result := pull(mut machine_time, mut buffer, mut params)
			for byte in 0 .. 4 { output[4 * index + byte] = u8((result >> (8 * byte)) & 255) }
		}
	}
	return i64(required)
}
