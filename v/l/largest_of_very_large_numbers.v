module main

const max_value = i64(1000000000000)

fn decimal_exponent(base i64) i64 {
	if base < 1 { return -1 }
	mut remaining := base
	mut exponent := i64(0)
	for remaining > 1 && remaining % 10 == 0 {
		remaining /= 10
		exponent++
	}
	if remaining == 1 { return exponent }
	return -1
}

fn valid_base(base i64) bool {
	return base == 0 || decimal_exponent(base) >= 0
}

fn source_score(base i64, exponent i64) i64 {
	if base == 0 { return 0 }
	if exponent == 0 { return 1 }
	return decimal_exponent(base) * exponent
}

@[export: 'largest_of_very_large_numbers']
pub fn largest_of_very_large_numbers(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length != 4 { return -2 }
		for i in 0 .. 4 { if values[i] < 0 || values[i] > max_value { return -2 } }
		if !valid_base(values[0]) || !valid_base(values[2]) { return -2 }
		a := source_score(values[0], values[1])
		b := source_score(values[2], values[3])
		if a > b { return 1 }
		if a < b { return -1 }
		return 0
	}
}
