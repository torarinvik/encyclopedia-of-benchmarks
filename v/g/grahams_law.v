module grahams_law

import math

const invalid_result = -1.0e300

fn rounded_six(value f64) f64 {
	if !(value >= 0.0 && value <= 1.0e6) { return invalid_result }
	scaled := value * 1_000_000.0
	mut lower := math.floor(scaled)
	fraction := scaled - lower
	if fraction >= 0.499 && fraction <= 0.501 { return invalid_result }
	if fraction > 0.5 { lower += 1.0 }
	return lower / 1_000_000.0
}

fn decode_positive(values &i64, index int) f64 {
	unsafe {
		result := *(&values[index] as &f64)
		if math.is_nan(result) || math.is_inf(result) || result < 1.0e-6 || result > 1.0e6 { return 0.0 }
		return result
	}
}

@[export: 'grahams_law']
pub fn grahams_law(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > 4 || values[0] < 0 || values[0] > 4 { return invalid_result }
	operation := values[0]
	if (operation == 0 && length != 3) || (operation != 0 && length != 4) { return invalid_result }
	first := decode_positive(values, 1)
	second := decode_positive(values, 2)
	if first == 0.0 || second == 0.0 { return invalid_result }
	mut result := 0.0
	if operation == 0 { result = math.sqrt(second / first) }
	else {
		third := decode_positive(values, 3)
		if third == 0.0 { return invalid_result }
		if operation == 1 { result = first * math.sqrt(third / second) }
		else if operation == 2 { result = first / math.sqrt(third / second) }
		else if operation == 3 { result = first / math.pow(second / third, 2.0) }
		else { result = math.pow(second / third, 2.0) / first }
	}
	if math.is_nan(result) || math.is_inf(result) { return invalid_result }
	return rounded_six(result)
}
