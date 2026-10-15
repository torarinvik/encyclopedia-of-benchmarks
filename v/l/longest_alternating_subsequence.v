module longest_alternating_subsequence

const max_length = 512

// Return the length of a strict longest alternating subsequence.
@[export: 'longest_alternating_subsequence']
pub fn longest_alternating_subsequence(values &i64, length usize) i64 {
	if length > max_length { return -1 }
	mut rising := [max_length]i64{init: 0}
	mut falling := [max_length]i64{init: 0}
	mut result := i64(1)
	for index := 0; index < int(length); index++ {
		value := unsafe { values[index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		rising[index] = 1
		falling[index] = 1
		for previous := 0; previous < index; previous++ {
			prior := unsafe { values[previous] }
			if prior < value && rising[index] < falling[previous] + 1 {
				rising[index] = falling[previous] + 1
			}
			if prior > value && falling[index] < rising[previous] + 1 {
				falling[index] = rising[previous] + 1
			}
		}
		if rising[index] > result { result = rising[index] }
		if falling[index] > result { result = falling[index] }
	}
	return result
}
