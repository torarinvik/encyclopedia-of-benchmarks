module longest_common_substring

const max_length = 256

@[export: 'longest_common_substring']
pub fn longest_common_substring(input &i64, length usize) i64 {
	if length < 2 || unsafe { input[0] } < 0 || unsafe { input[0] } > max_length { return -1 }
	first_length := int(unsafe { input[0] })
	if first_length + 2 > int(length) || unsafe { input[first_length+1] } < 0 || unsafe { input[first_length+1] } > max_length { return -1 }
	second_length := int(unsafe { input[first_length+1] })
	if int(length) != first_length + second_length + 2 { return -1 }
	first := 1; second := first_length + 2
	for i in 0 .. first_length { value := unsafe { input[first+i] }; if value < 32 || value > 126 { return -1 } }
	for j in 0 .. second_length { value := unsafe { input[second+j] }; if value < 32 || value > 126 { return -1 } }
	mut dp := [max_length + 1]i64{init: 0}
	mut best := i64(0)
	for i in 1 .. (first_length + 1) {
		mut j := second_length
		for j > 0 {
			if unsafe { input[first+i-1] == input[second+j-1] } { dp[j] = dp[j-1] + 1; if dp[j] > best { best = dp[j] } }
			else { dp[j] = 0 }
			j--
		}
	}
	return best
}
