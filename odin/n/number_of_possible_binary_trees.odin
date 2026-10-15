package number_of_possible_binary_trees

@(export)
number_of_possible_binary_trees :: proc "contextless" (node_count: i64) -> i64 {
	if node_count < 1 || node_count > 14 do return -1
	binomial: i64 = 1
	for index: i64 = 0; index < node_count; index += 1 {
		binomial *= 2 * node_count - index
		binomial /= index + 1
	}
	catalan := binomial / (node_count + 1)
	factorial: i64 = 1
	for factor: i64 = 2; factor <= node_count; factor += 1 { factorial *= factor }
	return catalan * factorial
}
