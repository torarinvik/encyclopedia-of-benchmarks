module snells_law

import math

const pi_value = 3.141592653589793238462643383279502884

fn round_two_even(value f64) f64 {
	scaled := value * 100.0
	lower := math.floor(scaled)
	fraction := scaled - lower
	mut rounded := i64(lower)
	if fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0) {
		rounded++
	}
	return f64(rounded) / 100.0
}

@[export: 'snells_law']
pub fn snells_law(n1 f64, n2 f64, incident_angle_degrees f64) f64 {
	if math.is_nan(n1) || math.is_nan(n2) || math.is_nan(incident_angle_degrees) ||
		n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 || incident_angle_degrees < -90.0 || incident_angle_degrees > 90.0 {
		return -1.0e300
	}
	incident_angle_radians := incident_angle_degrees * (pi_value / 180.0)
	refraction_sine := (n1 / n2) * math.sin(incident_angle_radians)
	mut scale := math.abs(refraction_sine)
	if scale < 1.0 { scale = 1.0 }
	if math.abs(refraction_sine - 1.0) <= 1.0e-9 * scale { return 90.0 }
	if math.abs(refraction_sine + 1.0) <= 1.0e-9 * scale { return -90.0 }
	if refraction_sine < -1.0 || refraction_sine > 1.0 { return -1.0e300 }
	refraction_angle_degrees := math.asin(refraction_sine) * (180.0 / pi_value)
	return round_two_even(refraction_angle_degrees)
}
