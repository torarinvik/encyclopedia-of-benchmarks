module count_different_palindromic_subsequences

const max_length = 20
const modulus = i64(1_000_000_007)

fn normalize(value i64) i64 {
	mut result := value % modulus
	if result < 0 { result += modulus }
	return result
}

@[export: 'count_different_palindromic_subsequences']
pub fn count_different_palindromic_subsequences(input &i64, length usize) i64 {
	if length < 1 || length > max_length + 2 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_length || length != usize(n_value) + 1 { return -1 }
		n := int(n_value)
		mut symbols := [max_length]int{}
		for i in 0 .. n {
			if input[i + 1] < 0 || input[i + 1] > 3 { return -1 }
			symbols[i] = int(input[i + 1])
		}
		if n == 0 { return 0 }
		mut next_equal := [max_length]int{}
		mut previous_equal := [max_length]int{}
		mut next_at := [4]int{}
		mut previous_at := [4]int{}
		for symbol in 0 .. 4 { next_at[symbol] = n; previous_at[symbol] = -1 }
		for i := n; i > 0; i-- {
			index := i - 1
			symbol := symbols[index]
			next_equal[index] = next_at[symbol]
			next_at[symbol] = index
		}
		for i in 0 .. n {
			symbol := symbols[i]
			previous_equal[i] = previous_at[symbol]
			previous_at[symbol] = i
		}
		mut dp := [max_length][max_length]i64{}
		for i in 0 .. n { dp[i][i] = 1 }
		for width in 2 .. n + 1 {
			for left in 0 .. n - width + 1 {
				right := left + width - 1
				inner := i64(0)
				if width > 2 { inner = dp[left + 1][right - 1] }
				if symbols[left] != symbols[right] {
					dp[left][right] = normalize(dp[left + 1][right] + dp[left][right - 1] - inner)
				} else {
					first := next_equal[left]
					last := previous_equal[right]
					mut value := i64(0)
					if first >= right || last <= left || first > last { value = 2 * inner + 2 }
					else if first == last { value = 2 * inner + 1 }
					else {
						mut duplicates := i64(0)
						if first + 1 <= last - 1 { duplicates = dp[first + 1][last - 1] }
						value = 2 * inner - duplicates
					}
					dp[left][right] = normalize(value)
				}
			}
		}
		return dp[0][n - 1]
	}
}
