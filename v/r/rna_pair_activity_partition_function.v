module rna_pair_activity_partition_function

const max_sequence_length = 16
const max_parseable_length = 122

fn pair_input_index(n int, left int, right int) int {
	preceding := left * (2 * n - left - 1) / 2
	return 1 + preceding + (right - left - 1)
}

@[export: 'rna_pair_activity_partition_function']
pub fn rna_pair_activity_partition_function(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 1 || length > max_parseable_length {
			return -1
		}
		n_value := input[0]
		if n_value < 0 || n_value > max_sequence_length {
			return -1
		}
		n := int(n_value)
		if length != usize(1 + n * (n - 1) / 2) {
			return -1
		}
		for index in 1 .. int(length) {
			if input[index] < 0 || input[index] > 3 {
				return -1
			}
		}
		if n == 0 {
			return 1
		}

		mut table := [max_sequence_length][max_sequence_length]i64{}
		for span in 1 .. n + 1 {
			for left in 0 .. n - span + 1 {
				right := left + span - 1
				mut total := i64(1)
				if left < right {
					total = table[left][right - 1]
				}
				for partner in left .. right {
					activity := input[pair_input_index(n, partner, right)]
					before := if partner == left { i64(1) } else { table[left][partner - 1] }
					inside := if partner + 1 >= right { i64(1) } else { table[partner + 1][right - 1] }
					total += before * inside * activity
				}
				table[left][right] = total
			}
		}
		return table[0][n - 1]
	}
}
