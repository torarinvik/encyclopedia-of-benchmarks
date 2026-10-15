module order_of_magnitude_conversion

import math

const max_value = 1e100

fn unit_exponent(code f64) int {
	if code == 0.0 { return 0 }
	if code == 1.0 { return 3 }
	if code == 2.0 { return 6 }
	if code == 3.0 { return 9 }
	if code == 4.0 { return 12 }
	if code == 5.0 { return 15 }
	if code == 6.0 { return 18 }
	if code == 7.0 { return 21 }
	if code == 8.0 { return 24 }
	return -1
}

// Preserve the source formula and operation order: value * 10^(from - to).
@[export: 'order_of_magnitude_conversion']
pub fn order_of_magnitude_conversion(value f64, from_unit_code f64, to_unit_code f64) f64 {
	if math.is_nan(value) || value < -max_value || value > max_value { return -1.0 }
	from_exp := unit_exponent(from_unit_code)
	to_exp := unit_exponent(to_unit_code)
	if from_exp < 0 || to_exp < 0 { return -1.0 }
	return value * math.pow(10.0, f64(from_exp - to_exp))
}
