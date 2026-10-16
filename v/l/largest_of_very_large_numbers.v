module main
import math

const max_value = i64(1000000000000)

fn source_score(base i64, exponent i64) f64 {
	if base == 0 { return 0.0 }
	if exponent == 0 { return 1.0 }
	return f64(exponent) * math.log10(f64(base))
}

fn valid_comparison_domain(base_a i64, exponent_a i64, base_b i64, exponent_b i64) bool {
	return exponent_a == exponent_b ||
		(base_a == base_b && (base_a == 0 || ((exponent_a == 0) == (exponent_b == 0))))
}

@[export: 'largest_of_very_large_numbers']
pub fn largest_of_very_large_numbers(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length != 4 { return -2 }
		for i in 0 .. 4 { if values[i] < 0 || values[i] > max_value { return -2 } }
		if !valid_comparison_domain(values[0], values[1], values[2], values[3]) { return -2 }
		a := source_score(values[0], values[1])
		b := source_score(values[2], values[3])
		if a > b { return 1 }
		if a < b { return -1 }
		return 0
	}
}
