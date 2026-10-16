module gamma

import math

const invalid_result = -1.0e300

fn gamma_recursive_impl(num f64) f64 {
	if num == 0.5 { return math.sqrt(3.14159265358979323846) }
	if num == 1.0 { return 1.0 }
	return (num - 1.0) * gamma_recursive_impl(num - 1.0)
}

@[export: 'gamma_recursive']
pub fn gamma_recursive(num f64) f64 {
	if num < 0.5 || num > 20.0 || num * 2.0 != math.floor(num * 2.0) { return invalid_result }
	return gamma_recursive_impl(num)
}
