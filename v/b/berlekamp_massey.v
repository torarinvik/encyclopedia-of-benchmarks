module berlekamp_massey

const modulus = i64(998244353)
const max_order = 8
const max_terms = 2 * max_order
const max_input_values = 1 + max_terms + 1

fn normalize(value i64) i64 {
	result := value % modulus
	return if result < 0 { result + modulus } else { result }
}

fn multiply(left i64, right i64) i64 {
	return (left * right) % modulus
}

fn power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = multiply(result, base) }
		base = multiply(base, base)
		exponent >>= 1
	}
	return result
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn infer_recurrence(sequence []i64, term_count int, mut coefficients []i64) int {
	mut current := []i64{len: max_terms + 1}
	mut previous := []i64{len: max_terms + 1}
	mut old := []i64{len: max_terms + 1}
	mut current_length := 0
	mut previous_length := 0
	mut last_index := -1
	mut last_discrepancy := i64(0)
	for index in 0 .. term_count {
		mut predicted := i64(0)
		limit := if current_length < index { current_length } else { index }
		for lag in 0 .. limit {
			predicted = normalize(predicted + multiply(sequence[index - lag - 1], current[lag]))
		}
		discrepancy := normalize(sequence[index] - predicted)
		if discrepancy == 0 { continue }
		if last_index < 0 {
			last_index = index
			last_discrepancy = discrepancy
			current_length = index + 1
			for lag in 0 .. current_length { current[lag] = 0 }
			continue
		}

		for lag in 0 .. current_length { old[lag] = current[lag] }
		old_length := current_length
		shift := index - last_index
		scale := multiply(discrepancy, power(last_discrepancy, modulus - 2))
		needed_length := previous_length + shift
		if current_length < needed_length {
			for lag in current_length .. needed_length { current[lag] = 0 }
			current_length = needed_length
		}
		current[shift - 1] = normalize(current[shift - 1] + scale)
		for lag in 0 .. previous_length {
			current[shift + lag] = normalize(current[shift + lag] - multiply(scale, previous[lag]))
		}
		if old_length - index < previous_length - last_index {
			for lag in 0 .. old_length { previous[lag] = old[lag] }
			previous_length = old_length
			last_index = index
			last_discrepancy = discrepancy
		}
	}
	for lag in 0 .. current_length { coefficients[lag] = current[lag] }
	return current_length
}

@[export: 'berlekamp_massey']
pub fn berlekamp_massey(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	bound_value := unsafe { input[0] }
	if bound_value < 1 || bound_value > max_order { return -1 }
	bound := int(bound_value)
	term_count := 2 * bound
	if length != usize(1 + term_count) { return -1 }

	mut sequence := []i64{len: max_terms}
	for index in 0 .. term_count {
		value := unsafe { input[1 + index] }
		if value < 0 || value >= modulus { return -1 }
		sequence[index] = value
	}
	mut coefficients := []i64{len: max_terms + 1}
	order := infer_recurrence(sequence, term_count, mut coefficients)
	if order > bound { return -1 }

	output_bytes := 8 * (order + 1)
	if unsafe { output == nil } || capacity < output_bytes { return -2 }
	store_i64_le(mut output, 0, i64(order))
	for lag in 0 .. order {
		store_i64_le(mut output, 8 * (lag + 1), coefficients[lag])
	}
	return i64(output_bytes)
}
