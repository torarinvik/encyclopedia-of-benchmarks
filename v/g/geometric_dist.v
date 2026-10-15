module geometric_dist

import math

const invalid_result = -1.0e300

fn geometric_cdf(p f32, k i64) f32 {
	power := f32(math.pow(f64(1.0 - p), f64(k)))
	return f32(1.0) - power
}

// Deterministic operations of the source's first-success geometric distribution.
@[export: 'geometric_dist']
pub fn geometric_dist(values &i64, length usize) f64 {
	if length < 2 { return invalid_result }
	operation := unsafe { values[0] }
	p_code := unsafe { values[1] }
	if p_code < 0 || p_code > 2 { return invalid_result }
	probabilities := [f32(0.25), f32(0.5), f32(0.75)]!
	p := probabilities[int(p_code)]
	if operation >= 0 && operation <= 2 {
		if length != 2 { return invalid_result }
		if operation == 0 { return f64(f32(1.0) / p) }
		variance := (f32(1.0) - p) / (p * p)
		if operation == 1 { return f64(variance) }
		return f64(f32(math.sqrt(f64(variance))))
	}
	if operation == 3 || operation == 4 {
		if length != 3 { return invalid_result }
		k := unsafe { values[2] }
		if operation == 3 && (k < 1 || k > 16) { return invalid_result }
		if operation == 4 && (k < 0 || k > 16) { return invalid_result }
		if operation == 3 {
			power := f32(math.pow(f64(f32(1.0) - p), f64(k - 1)))
			return f64(power * p)
		}
		return f64(geometric_cdf(p, k))
	}
	if operation == 5 {
		if length != 3 { return invalid_result }
		cdf_code := unsafe { values[2] }
		if cdf_code < 0 || cdf_code > 2 { return invalid_result }
		cdf_values := [f32(0.25), f32(0.5), f32(0.75)]!
		cdf := cdf_values[int(cdf_code)]
		numerator := f32(math.log(f64(f32(1.0) - cdf)))
		denominator := f32(math.log(f64(f32(1.0) - p)))
		return f64(numerator / denominator)
	}
	if operation == 6 {
		if length != 4 { return invalid_result }
		minimum := unsafe { values[2] }
		maximum := unsafe { values[3] }
		if minimum < 1 || maximum < minimum || maximum > 16 { return invalid_result }
		return f64(geometric_cdf(p, maximum) - geometric_cdf(p, minimum - 1))
	}
	invalid_result
}
