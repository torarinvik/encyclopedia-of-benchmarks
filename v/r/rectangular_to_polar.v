module main
import math

const invalid_result = -1.0e300
const degree_factor = 57.2957795130823208768

fn round_two_away(value f64) f64 {
	if value == 0.0 { return value }
	scaled := value * 100.0
	if scaled >= 0.0 { return f64(i64(scaled + 0.5)) / 100.0 }
	units := i64(scaled - 0.5)
	if units == 0 { return -0.0 }
	return f64(units) / 100.0
}

@[export: 'rectangular_to_polar']
pub fn rectangular_to_polar(real f64, imag f64, component f64) f64 {
	if real != real || imag != imag || component != component ||
		math.abs(real) > 1000000.0 || math.abs(imag) > 1000000.0 ||
		(component != 0.0 && component != 1.0) { return invalid_result }
	if component == 0.0 { return round_two_away(math.sqrt(real * real + imag * imag)) }
	return round_two_away(math.atan2(imag, real) * degree_factor)
}
