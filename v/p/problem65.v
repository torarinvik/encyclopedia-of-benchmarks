module problem65

const max_digits = 256

@[export: 'problem65']
pub fn problem65(max_n i64) i64 {
	if max_n < 1 || max_n > 100 { return -1 }
	mut previous := [max_digits]i64{}
	mut current := [max_digits]i64{}
	mut next := [max_digits]i64{}
	previous[0] = 1
	current[0] = 2
	mut previous_length := 1
	mut current_length := 1
	mut i := i64(2)
	for i <= max_n {
		coefficient := if i % 3 == 0 { (2 * i) / 3 } else { i64(1) }
		mut carry := i64(0)
		for position := 0; position < current_length; position++ {
			old := if position < previous_length { previous[position] } else { i64(0) }
			total := coefficient * current[position] + old + carry
			next[position] = total % 10
			carry = total / 10
		}
		mut next_length := current_length
		for carry != 0 {
			next[next_length] = carry % 10
			next_length++
			carry /= 10
		}
		for position := 0; position < current_length; position++ { previous[position] = current[position] }
		for position := 0; position < next_length; position++ { current[position] = next[position] }
		previous_length = current_length
		current_length = next_length
		i++
	}
	mut digit_sum := i64(0)
	for position := 0; position < current_length; position++ { digit_sum += current[position] }
	return digit_sum
}
