module sylvester_sequence

fn sylvester_term(n i64) i64 {
	if n == 1 {
		return 2
	}
	previous := sylvester_term(n - 1)
	return previous * (previous - 1) + 1
}

// Recursive Sylvester recurrence on the signed 64-bit benchmark domain.
@[export: 'sylvester_sequence']
pub fn sylvester_sequence(n i64) i64 {
	if n < 1 || n > 7 {
		return -1
	}
	return sylvester_term(n)
}
