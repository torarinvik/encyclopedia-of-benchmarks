package next_higher_number_with_same_number_of_set_bits

// Return the next larger positive integer with the same population count.
@(export)
next_higher_number_with_same_number_of_set_bits :: proc "c" (input: i64) -> i64 {
	if input < 1 || input > 1_073_741_823 do return -1
	right_one := input & -input
	next_higher := input + right_one
	packed_ones := (input ^ next_higher) / right_one
	return next_higher | (packed_ones >> 2)
}
