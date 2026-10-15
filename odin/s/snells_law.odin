package snells_law

import "core:math"

PI :: 3.141592653589793238462643383279502884

round_two_even :: proc(value: f64) -> f64 {
	scaled := value * 100.0
	lower := math.floor(scaled)
	fraction := scaled - lower
	rounded := i64(lower)
	if fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0) do rounded += 1
	return f64(rounded) / 100.0
}

@(export)
snells_law :: proc "c" (n1, n2, incident_angle_degrees: f64) -> f64 {
	if math.isnan_f64(n1) || math.isnan_f64(n2) || math.isnan_f64(incident_angle_degrees) ||
		n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 || incident_angle_degrees < -90.0 || incident_angle_degrees > 90.0 do return -1.0e300
	incident_angle_radians := incident_angle_degrees * (PI / 180.0)
	refraction_sine := (n1 / n2) * math.sin_f64(incident_angle_radians)
	scale := math.abs(refraction_sine)
	if scale < 1.0 do scale = 1.0
	if math.abs(refraction_sine - 1.0) <= 1.0e-9 * scale do return 90.0
	if math.abs(refraction_sine + 1.0) <= 1.0e-9 * scale do return -90.0
	if refraction_sine < -1.0 || refraction_sine > 1.0 do return -1.0e300
	refraction_angle_degrees := math.asin_f64(refraction_sine) * (180.0 / PI)
	return round_two_even(refraction_angle_degrees)
}
