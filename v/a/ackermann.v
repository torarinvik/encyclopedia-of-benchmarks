module ackermann

fn ackermann_value(m i64, n i64) i64 {
	if m == 0 { return n + 1 }
	if n == 0 { return ackermann_value(m - 1, 1) }
	return ackermann_value(m - 1, ackermann_value(m, n - 1))
}

@[export: 'ackermann']
pub fn ackermann(m i64, n i64) i64 {
	if m < 0 || m > 3 || n < 0 || n > 5 { return -1 }
	return ackermann_value(m, n)
}
