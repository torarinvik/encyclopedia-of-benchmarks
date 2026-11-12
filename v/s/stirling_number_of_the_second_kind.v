module stirling_number_of_the_second_kind

const max_n = 16
const modulus = i64(998244353)

@[export: 'stirling_number_of_the_second_kind']
pub fn stirling_number_of_the_second_kind(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_n { return -1 }
		n := int(n_value)

		mut row := [17]i64{}
		row[0] = 1
		mut current_n := 1
		for current_n <= n {
			mut k := current_n
			for k > 0 {
				row[k] = (row[k - 1] + i64(k) * row[k]) % modulus
				k--
			}
			row[0] = 0
			current_n++
		}

		mut result := i64(0)
		for k in 0 .. n + 1 {
			next := i64(k + 1)
			weight := next * next * next
			result = (result + weight * row[k]) % modulus
		}
		return result
	}
}
