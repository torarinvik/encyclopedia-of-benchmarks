module strange_printer

const max_length = 8
const table_side = 9

@[export: 'strange_printer']
pub fn strange_printer(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 10 { return -1 }
		n_value := input[0]
		if n_value < 0 || n_value > max_length || length != usize(n_value + 1) { return -1 }
		n := int(n_value)
		for position in 0 .. n {
			if input[position + 1] < 0 || input[position + 1] > 2 { return -1 }
		}
		if n == 0 { return 0 }

		mut dp := [81]i64{}
		mut left := n
		for left > 0 {
			left--
			dp[left * table_side + left] = 1
			for right in left + 1 .. n {
				mut best := dp[(left + 1) * table_side + right] + 1
				for merge in left + 1 .. right + 1 {
					if input[left + 1] != input[merge + 1] { continue }
					mut middle := i64(0)
					if merge > left + 1 { middle = dp[(left + 1) * table_side + merge - 1] }
					candidate := middle + dp[merge * table_side + right]
					if candidate < best { best = candidate }
				}
				dp[left * table_side + right] = best
			}
		}
		return dp[n - 1]
	}
}
