module first_law_of_thermodynamics

@[export: 'first_law_of_thermodynamics']
pub fn first_law_of_thermodynamics(operation f64, a f64, b f64) f64 {
	if operation != operation || a != a || b != b { return -1e300 }
	if operation < 0.0 || operation > 2.0 || operation != f64(i64(operation)) { return -1e300 }
	if a < -1000000.0 || a > 1000000.0 || b < -1000000.0 || b > 1000000.0 { return -1e300 }
	if a != f64(i64(a)) || b != f64(i64(b)) { return -1e300 }
	if operation == 0.0 { return a - b }
	if operation == 1.0 { return a + b }
	return a - b
}
