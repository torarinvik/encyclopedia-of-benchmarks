module trinomial_triangle

fn trinomial_value(n i64, k i64) i64 {
	if n == 0 && k == 0 { return 1 }
	if k < -n || k > n { return 0 }
	return trinomial_value(n - 1, k - 1) +
		trinomial_value(n - 1, k) +
		trinomial_value(n - 1, k + 1)
}

@[export: 'trinomial_triangle']
pub fn trinomial_triangle(n i64, k i64) i64 {
	if n < 0 || n > 10 || k < -10 || k > 10 { return -1 }
	return trinomial_value(n, k)
}
