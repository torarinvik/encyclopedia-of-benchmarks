module additive_persistence

// Count repeated decimal digit-sum steps until one digit remains.
@[export: 'additive_persistence']
pub fn additive_persistence(input_value i64) i64 {
	if input_value < 0 { return -1 }
	mut input := input_value
	mut steps := i64(0)
	for input >= 10 {
		mut total := i64(0)
		mut remaining := input
		for remaining > 0 {
			total += remaining % 10
			remaining /= 10
		}
		input = total
		steps++
	}
	return steps
}
