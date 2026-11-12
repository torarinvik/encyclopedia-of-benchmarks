// Clean-room bounded implementation of the Library Checker sequence-counting task.
module number_of_increasing_sequences_between_two_sequences

const max_n = 64
const max_m = 64
const max_input_length = 130
const modulus = i64(998244353)

@[export: 'number_of_increasing_sequences_between_two_sequences']
pub fn number_of_increasing_sequences_between_two_sequences(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_m { return -1 }
		n := int(input[0])
		m := int(input[1])
		if int(length) != 2 + 2 * n { return -1 }
		mut lower := [max_n]i64{}
		mut upper := [max_n]i64{}
		for position in 0 .. n {
			lower[position] = input[2 + position]
			upper[position] = input[2 + n + position]
			if lower[position] < 0 || lower[position] >= upper[position] || upper[position] > i64(m) { return -1 }
		}
		mut previous := [max_m]i64{}
		mut current := [max_m]i64{}
		for value in int(lower[0]) .. int(upper[0]) { previous[value] = 1 }
		for position in 1 .. n {
			mut prefix := i64(0)
			for value in 0 .. m {
				prefix += previous[value]
				if prefix >= modulus { prefix -= modulus }
				current[value] = 0
				if lower[position] <= i64(value) && i64(value) < upper[position] { current[value] = prefix }
			}
			for value in 0 .. m { previous[value] = current[value] }
		}
		mut answer := i64(0)
		for value in 0 .. m {
			answer += previous[value]
			if answer >= modulus { answer -= modulus }
		}
		return answer
	}
}
