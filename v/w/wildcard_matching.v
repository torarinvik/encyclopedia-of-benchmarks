module wildcard_matching

// Full-string wildcard matching for lowercase ASCII text.
@[export: 'wildcard_matching']
pub fn wildcard_matching(input &i64, length usize) i64 {
	if length < 2 || length > 35 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 12 || input[1] < 0 || input[1] > 20 { return -1 }
		text_length := int(input[0])
		pattern_length := int(input[1])
		if int(length) != 2 + text_length + pattern_length { return -1 }
		for i in 0 .. text_length {
			if input[2 + i] < 97 || input[2 + i] > 122 { return -1 }
		}
		pattern_start := 2 + text_length
		for j in 0 .. pattern_length {
			token := input[pattern_start + j]
			if !((token >= 97 && token <= 122) || token == 42 || token == 63) { return -1 }
		}

		mut dp := [273]bool{}
		dp[0] = true
		for j in 1 .. pattern_length + 1 {
			if input[pattern_start + j - 1] == 42 { dp[j] = dp[j - 1] }
		}
		for i in 1 .. text_length + 1 {
			for j in 1 .. pattern_length + 1 {
				token := input[pattern_start + j - 1]
				cell := i * 21 + j
				if token == input[1 + i] || token == 63 {
					dp[cell] = dp[(i - 1) * 21 + j - 1]
				} else if token == 42 {
					dp[cell] = dp[(i - 1) * 21 + j] || dp[i * 21 + j - 1]
				}
			}
		}
		if dp[text_length * 21 + pattern_length] { return 1 }
		return 0
	}
}
