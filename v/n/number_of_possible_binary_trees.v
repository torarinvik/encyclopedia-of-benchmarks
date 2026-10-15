module number_of_possible_binary_trees

@[export: 'number_of_possible_binary_trees']
pub fn number_of_possible_binary_trees(node_count i64) i64 {
	if node_count < 1 || node_count > 14 { return -1 }
	mut binomial := i64(1)
	for index in 0 .. int(node_count) {
		binomial *= 2 * node_count - i64(index)
		binomial /= i64(index + 1)
	}
	catalan := binomial / (node_count + 1)
	mut factorial := i64(1)
	for factor in 2 .. int(node_count) + 1 { factorial *= i64(factor) }
	return catalan * factorial
}
