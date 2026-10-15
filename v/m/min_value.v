@[export: 'min_value']
pub fn min_value(a i64, b i64) i64 {
	if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 { return -1 }
	return if a <= b { a } else { b }
}
