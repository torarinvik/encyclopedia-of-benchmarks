package additive_persistence

// Count repeated decimal digit-sum steps until one digit remains.
@(export)
additive_persistence :: proc "c" (input_value: i64) -> i64 {
	if input_value < 0 do return -1
	input := input_value
	steps := i64(0)
	for input >= 10 {
		total := i64(0)
		remaining := input
		for remaining > 0 {
			total += remaining % 10
			remaining /= 10
		}
		input = total
		steps += 1
	}
	return steps
}
