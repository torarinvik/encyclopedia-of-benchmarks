@[export: 'powers_of10_sequence']
pub fn powers_of10_sequence(index i64) i64 {
	if index < 0 || index > 18 { return -1 }
	mut value := i64(1)
	for _ in 0 .. index {
		value *= 10
	}
	return value
}
