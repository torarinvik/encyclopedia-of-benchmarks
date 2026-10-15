@[export: 'fermat_numbers_sequence']
pub fn fermat_numbers_sequence(index i64) i64 {
	if index < 0 || index > 5 { return -1 }
	mut value := i64(2)
	for _ in 0 .. index { value *= value }
	return value + 1
}
