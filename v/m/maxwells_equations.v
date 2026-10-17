module maxwells_equations

import math

const max_physical = i64(1000000000000000)
const max_flux_rate = i64(1000000000000000000)
const min_constant = i64(1000000)
const max_constant = i64(1000000000000000)
const epsilon_default = 8.8541878128e-12
const pi_value = 3.14159265358979323846264338327950288
const mu_default = 4.0 * pi_value * 1e-7
const invalid_result = -1e300

fn in_range(value i64, limit i64) bool { return value >= -limit && value <= limit }
fn decode_constant(raw i64, fallback f64, mut value f64) bool {
	if raw == 0 { value = fallback; return true }
	if raw < min_constant || raw > max_constant { return false }
	value = f64(raw) / 1e18
	return true
}
fn law_result(actual f64, expected f64) f64 {
	tolerance := if expected != 0.0 { 0.01 * math.abs(expected) } else { 1e-10 }
	return if math.abs(actual - expected) <= tolerance { 1.0 } else { 0.0 }
}

@[export: 'maxwells_equations']
pub fn maxwells_equations(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 1 || length > 7 { return invalid_result }
	unsafe {
		operation := input[0]
		if operation == 0 {
			if length != 5 { return invalid_result }
			field, area, charge, epsilon_raw := input[1], input[2], input[3], input[4]
			if !in_range(field, max_physical) || area < 0 || area > max_physical || !in_range(charge, max_physical) { return invalid_result }
			mut epsilon := f64(0.0)
			if !decode_constant(epsilon_raw, epsilon_default, mut epsilon) { return invalid_result }
			electric_flux := (f64(field) / 1e12) * (f64(area) / 1e12)
			expected_flux := (f64(charge) / 1e12) / epsilon
			return law_result(electric_flux, expected_flux)
		}
		if operation == 1 {
			if length != 3 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical) { return invalid_result }
			circulation := f64(input[1]) / 1e12
			expected := -(f64(input[2]) / 1e12)
			return law_result(circulation, expected)
		}
		if operation == 2 {
			if length != 6 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical) || !in_range(input[3], max_flux_rate) { return invalid_result }
			mut mu := f64(0.0); mut epsilon := f64(0.0)
			if !decode_constant(input[4], mu_default, mut mu) || !decode_constant(input[5], epsilon_default, mut epsilon) { return invalid_result }
			displacement_current := epsilon * (f64(input[3]) / 1e6)
			total_current := (f64(input[2]) / 1e12) + displacement_current
			expected := mu * total_current
			return law_result(f64(input[1]) / 1e12, expected)
		}
		if operation == 3 || operation == 4 {
			if length != 3 { return invalid_result }
			mut mu := f64(0.0); mut epsilon := f64(0.0)
			if !decode_constant(input[1], mu_default, mut mu) || !decode_constant(input[2], epsilon_default, mut epsilon) { return invalid_result }
			if operation == 3 { return 1.0 / math.sqrt(mu * epsilon) }
			return math.sqrt(mu / epsilon)
		}
		if operation == 5 {
			if length != 4 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical) { return invalid_result }
			mut mu := f64(0.0)
			if !decode_constant(input[3], mu_default, mut mu) { return invalid_result }
			return ((f64(input[1]) / 1e12) * (f64(input[2]) / 1e12)) / mu
		}
		if operation == 6 {
			if length != 5 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical) { return invalid_result }
			mut epsilon := f64(0.0); mut mu := f64(0.0)
			if !decode_constant(input[3], epsilon_default, mut epsilon) || !decode_constant(input[4], mu_default, mut mu) { return invalid_result }
			electric_field := f64(input[1]) / 1e12
			magnetic_field := f64(input[2]) / 1e12
			electric_energy := 0.5 * epsilon * (electric_field * electric_field)
			magnetic_energy := 0.5 * (magnetic_field * magnetic_field) / mu
			return electric_energy + magnetic_energy
		}
		return invalid_result
	}
}
