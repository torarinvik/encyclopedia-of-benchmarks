module powers_of2_sequence

// Return a term from the bounded powers-of-two sequence.
@[export: 'powers_of2_sequence']
pub fn powers_of2_sequence(index i64) i64 {
	if index < 0 || index > 62 { return -1 }
	mut value := i64(1)
	for _ in 0 .. index {
		value *= 2
	}
	return value
}
