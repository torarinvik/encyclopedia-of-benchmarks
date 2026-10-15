module sum_of_arithmetic_series

const invalid_result = -1.0e300

@[export: 'sum_of_arithmetic_series']
pub fn sum_of_arithmetic_series(packed &i64, length usize) f64 {
	if length != 3 { return invalid_result }
	a := unsafe { packed[0] }
	d := unsafe { packed[1] }
	n := unsafe { packed[2] }
	if a < -1000 || a > 1000 || d < -1000 || d > 1000 || n < 1 || n > 1000 { return invalid_result }
	result := n * (2 * a + (n - 1) * d) / 2
	return f64(result)
}
