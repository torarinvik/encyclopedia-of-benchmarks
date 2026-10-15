package first_law_of_thermodynamics

@(export)
first_law_of_thermodynamics :: proc "c" (operation, a, b: f64) -> f64 {
	if operation != operation || a != a || b != b do return -1e300
	if operation < 0.0 || operation > 2.0 || operation != f64(i64(operation)) do return -1e300
	if a < -1000000.0 || a > 1000000.0 || b < -1000000.0 || b > 1000000.0 do return -1e300
	if a != f64(i64(a)) || b != f64(i64(b)) do return -1e300
	if operation == 0.0 do return a - b
	if operation == 1.0 do return a + b
	return a - b
}
