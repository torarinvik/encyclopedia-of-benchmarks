module tribonacci_numbers_sequence

// Zero-based Tribonacci sequence with source seeds 1, 1, 1.
@[export: 'tribonacci_numbers_sequence']
pub fn tribonacci_numbers_sequence(index i64) i64 {
	if index < 0 || index > 60 { return -1 }
	if index < 3 { return 1 }

	mut first := i64(1)
	mut second := i64(1)
	mut third := i64(1)
	for i := i64(3); i <= index; i++ {
		next := first + second + third
		first = second
		second = third
		third = next
	}
	return third
}
