module problem9

@[export: 'problem9']
pub fn problem9(total i64) i64 {
	if total < 3 || total > 1000 { return -1 }
	mut a := i64(1)
	for a <= total / 3 {
		mut b := a + 1
		for 2 * b < total - a {
			c := total - a - b
			if a * a + b * b == c * c { return a * b * c }
			b++
		}
		a++
	}
	return -1
}
