@[export: 'matchstick_triangle_sequence']
pub fn matchstick_triangle_sequence(n i64) i64 {
	if n < 0 || n > 1000000 { return -1 }
	return (n * (n + 2) * (2 * n + 1)) / 8
}
