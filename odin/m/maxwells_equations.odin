package maxwells_equations

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
MAX_PHYSICAL :: i64 = 1_000_000_000_000_000
MAX_FLUX_RATE :: i64 = 1_000_000_000_000_000_000
MIN_CONSTANT :: i64 = 1_000_000
MAX_CONSTANT :: i64 = 1_000_000_000_000_000
EPSILON_DEFAULT :: f64 = 8.8541878128e-12
MU_DEFAULT :: f64 = 4.0 * 3.14159265358979323846264338327950288 * 1e-7

in_range :: proc "contextless" (value, limit: i64) -> bool { return value >= -limit && value <= limit }
decode_constant :: proc "contextless" (raw: i64, fallback: f64, value: ^f64) -> bool {
	if raw == 0 do { value^ = fallback; return true }
	if raw < MIN_CONSTANT || raw > MAX_CONSTANT do return false
	value^ = f64(raw) / 1e18
	return true
}
law_result :: proc "contextless" (actual, expected: f64) -> f64 {
	tolerance := if expected != 0 do 0.01 * math.abs(expected) else 1e-10
	return if math.abs(actual - expected) <= tolerance do 1.0 else 0.0
}

@(export)
maxwells_equations :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 1 || length > 7 do return INVALID_RESULT
	operation := input[0]
	if operation == 0 {
		if length != 5 do return INVALID_RESULT
		field, area, charge, epsilon_raw := input[1], input[2], input[3], input[4]
		if !in_range(field, MAX_PHYSICAL) || area < 0 || area > MAX_PHYSICAL || !in_range(charge, MAX_PHYSICAL) do return INVALID_RESULT
		 epsilon: f64
		if !decode_constant(epsilon_raw, EPSILON_DEFAULT, &epsilon) do return INVALID_RESULT
		electric_flux := (f64(field) / 1e12) * (f64(area) / 1e12)
		expected_flux := (f64(charge) / 1e12) / epsilon
		return law_result(electric_flux, expected_flux)
	}
	if operation == 1 {
		if length != 3 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL) do return INVALID_RESULT
		circulation := f64(input[1]) / 1e12
		expected := -(f64(input[2]) / 1e12)
		return law_result(circulation, expected)
	}
	if operation == 2 {
		if length != 6 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL) || !in_range(input[3], MAX_FLUX_RATE) do return INVALID_RESULT
		mu, epsilon: f64
		if !decode_constant(input[4], MU_DEFAULT, &mu) || !decode_constant(input[5], EPSILON_DEFAULT, &epsilon) do return INVALID_RESULT
		displacement_current := epsilon * (f64(input[3]) / 1e6)
		total_current := (f64(input[2]) / 1e12) + displacement_current
		expected := mu * total_current
		return law_result(f64(input[1]) / 1e12, expected)
	}
	if operation == 3 || operation == 4 {
		if length != 3 do return INVALID_RESULT
		mu, epsilon: f64
		if !decode_constant(input[1], MU_DEFAULT, &mu) || !decode_constant(input[2], EPSILON_DEFAULT, &epsilon) do return INVALID_RESULT
		if operation == 3 do return 1.0 / math.sqrt(mu * epsilon)
		return math.sqrt(mu / epsilon)
	}
	if operation == 5 {
		if length != 4 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL) do return INVALID_RESULT
		mu: f64
		if !decode_constant(input[3], MU_DEFAULT, &mu) do return INVALID_RESULT
		return ((f64(input[1]) / 1e12) * (f64(input[2]) / 1e12)) / mu
	}
	if operation == 6 {
		if length != 5 || !in_range(input[1], MAX_PHYSICAL) || !in_range(input[2], MAX_PHYSICAL) do return INVALID_RESULT
		epsilon, mu: f64
		if !decode_constant(input[3], EPSILON_DEFAULT, &epsilon) || !decode_constant(input[4], MU_DEFAULT, &mu) do return INVALID_RESULT
		electric := 0.5 * epsilon * math.pow(f64(input[1]) / 1e12, 2.0)
		magnetic := 0.5 * math.pow(f64(input[2]) / 1e12, 2.0) / mu
		return electric + magnetic
	}
	return INVALID_RESULT
}
