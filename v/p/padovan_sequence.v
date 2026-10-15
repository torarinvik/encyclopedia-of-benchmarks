module padovan_sequence

@[export: 'padovan_sequence']
pub fn padovan_sequence(index i64) i64 {
	if index < 0 || index > 156 { return -1 }
	if index <= 2 { return 1 }
	mut a := i64(1)
	mut b := i64(1)
	mut c := i64(1)
	mut result := i64(0)
	mut i := i64(3)
	for i <= index {
		result = a + b
		a = b
		b = c
		c = result
		i++
	}
	return result
}
