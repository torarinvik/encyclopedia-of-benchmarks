package geometric_dist

import "core:c"
import "core:math"

GEOMETRIC_INVALID_RESULT :: -1.0e300

geometric_cdf :: proc(p: f32, k: i64) -> f32 {
	power := f32(math.pow_f64(f64(1.0f - p), f64(k)))
	return 1.0f - power
}

// Deterministic operations of the source's first-success geometric distribution.
@(export)
geometric_dist :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 2 do return GEOMETRIC_INVALID_RESULT
	operation := values[0]
	p_code := values[1]
	if p_code < 0 || p_code > 2 do return GEOMETRIC_INVALID_RESULT
	probabilities := [3]f32{0.25, 0.5, 0.75}
	p := probabilities[p_code]
	if operation >= 0 && operation <= 2 {
		if length != 2 do return GEOMETRIC_INVALID_RESULT
		if operation == 0 do return f64(1.0f / p)
		variance := (1.0f - p) / (p * p)
		if operation == 1 do return f64(variance)
		return f64(f32(math.sqrt_f64(f64(variance))))
	}
	if operation == 3 || operation == 4 {
		if length != 3 do return GEOMETRIC_INVALID_RESULT
		k := values[2]
		if operation == 3 && (k < 1 || k > 16) do return GEOMETRIC_INVALID_RESULT
		if operation == 4 && (k < 0 || k > 16) do return GEOMETRIC_INVALID_RESULT
		if operation == 3 {
			power := f32(math.pow_f64(f64(1.0f - p), f64(k - 1)))
			return f64(power * p)
		}
		return f64(geometric_cdf(p, k))
	}
	if operation == 5 {
		if length != 3 || values[2] < 0 || values[2] > 2 do return GEOMETRIC_INVALID_RESULT
		cdf_values := [3]f32{0.25, 0.5, 0.75}
		cdf := cdf_values[values[2]]
		numerator := f32(math.log_f64(f64(1.0f - cdf)))
		denominator := f32(math.log_f64(f64(1.0f - p)))
		return f64(numerator / denominator)
	}
	if operation == 6 {
		if length != 4 do return GEOMETRIC_INVALID_RESULT
		minimum := values[2]
		maximum := values[3]
		if minimum < 1 || maximum < minimum || maximum > 16 do return GEOMETRIC_INVALID_RESULT
		return f64(geometric_cdf(p, maximum) - geometric_cdf(p, minimum - 1))
	}
	return GEOMETRIC_INVALID_RESULT
}
