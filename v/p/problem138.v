module problem138

@[export: 'problem138']
pub fn problem138(count i64) i64 {
	if count > 14 { return -1 }
	if count <= 0 { return 0 }
	mut m := i64(2)
	mut l := i64(1)
	mut total := i64(0)
	for _ in 0 .. int(count) {
		next_m := 9 * m + 20 * l
		next_l := 4 * m + 9 * l
		m = next_m
		l = next_l
		total += l
	}
	return total
}
