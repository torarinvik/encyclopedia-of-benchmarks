module next_higher_number_with_same_number_of_set_bits

// Return the next larger positive integer with the same population count.
@[export: 'next_higher_number_with_same_number_of_set_bits']
pub fn next_higher_number_with_same_number_of_set_bits(input i64) i64 {
	if input < 1 || input > 1_073_741_823 { return -1 }
	right_one := input & -input
	next_higher := input + right_one
	packed_ones := (input ^ next_higher) / right_one
	return next_higher | (packed_ones >> 2)
}
