module perrin_number

@[export: 'perrin_number']
pub fn perrin_number(index i64) i64 {
	if index < 0 || index > 155 { return -1 }
	if index == 0 { return 3 }
	if index == 1 { return 0 }
	if index == 2 { return 2 }
	mut a := i64(3)
	mut b := i64(0)
	mut c := i64(2)
	mut result := i64(0)
	for mut i := i64(3); i <= index; i++ {
		result = a + b
		a = b
		b = c
		c = result
	}
	return result
}
