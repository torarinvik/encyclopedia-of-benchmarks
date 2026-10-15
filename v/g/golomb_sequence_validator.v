module golomb_sequence_validator

const max_n = 1024

@[export: 'golomb_sequence_validator']
pub fn golomb_sequence_validator(input &i64, length usize) i64 {
	if length < 1 || length > max_n || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(n) { return -1 }
		for index in 1 .. n {
			if input[index] < -2147483648 || input[index] > 2147483647 { return -1 }
		}

		mut dp := [max_n]i64{init: 0}
		dp[0] = 1
		for i in 1 .. n {
			previous := int(dp[i - 1])
			nested := int(dp[previous])
			source := i - nested
			dp[i] = 1 + dp[source]
		}
		for index in 1 .. n {
			if input[index] != dp[index] { return 0 }
		}
		return 1
	}
}
