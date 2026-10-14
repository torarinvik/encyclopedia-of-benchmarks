module ceil

const max_values = 256
const max_input_values = 1 + 2 * max_values
const denominator_limit = 1_000_000

fn ceil_division(numerator i64, denominator i64) i64 {
	if numerator >= 0 {
		mut quotient := numerator / denominator
		if numerator % denominator != 0 { quotient++ }
		return quotient
	}
	return -((-numerator) / denominator)
}

@[export: 'ceil_benchmark']
pub fn ceil_benchmark(values &i64, length usize) i64 {
	if length < 1 || length > max_input_values { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > max_values { return -1 }
	count := int(count_value)
	if int(length) != 1 + 2 * count { return -1 }
	numerator_limit := i64(1_000_000) * i64(1_000_000)
	result_offset := numerator_limit + 1
	for i in 0 .. count {
		numerator := unsafe { values[1 + 2 * i] }
		denominator := unsafe { values[2 + 2 * i] }
		if numerator < -numerator_limit || numerator > numerator_limit ||
			denominator < 1 || denominator > denominator_limit { return -1 }
	}
	mut checksum := i64(0)
	for i in 0 .. count {
		numerator := unsafe { values[1 + 2 * i] }
		denominator := unsafe { values[2 + 2 * i] }
		result := ceil_division(numerator, denominator)
		checksum += i64(i + 1) * (result + result_offset)
	}
	return checksum
}
