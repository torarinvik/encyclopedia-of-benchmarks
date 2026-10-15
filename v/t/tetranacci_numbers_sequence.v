@[export: 'tetranacci_numbers_sequence']
pub fn tetranacci_numbers_sequence(index i64) i64 {
	if index < 0 || index > 68 { return -1 }
	mut a := i64(1)
	mut b := i64(1)
	mut c := i64(1)
	mut d := i64(1)
	if index <= 3 { return 1 }
	for _ in 4 .. index + 1 {
		next := a + b + c + d
		a = b
		b = c
		c = d
		d = next
	}
	return d
}
