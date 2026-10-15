module number_persistence

// Multiplicative persistence for nonnegative Java int inputs.
@[export: 'number_persistence']
pub fn number_persistence(input_value i64) i64 {
	if input_value < 0 || input_value > 2_147_483_647 { return -1 }
	mut input := input_value
	mut steps := i64(0)
	for input >= 10 {
		mut product := i64(1)
		mut remaining := input
		for remaining > 0 {
			product *= remaining % 10
			remaining /= 10
		}
		input = product
		steps++
	}
	return steps
}
