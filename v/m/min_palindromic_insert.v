module min_palindromic_insert

const max_n = 256
const max_output = 527

fn write_i64(mut output &u8, position int, value i64) int {
	bits := u64(value)
	unsafe { for i in 0 .. 8 { output[position + i] = u8((bits >> (8 * i)) & 255) } }
	return position + 8
}

@[export: 'min_palindromic_insert']
pub fn min_palindromic_insert(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_n + 1) { return -1 }
	unsafe {
		n_value := input[0]
		if n_value < 1 || n_value > max_n || length != usize(n_value + 1) { return -1 }
		n := int(n_value)
		mut chars := [max_n]u8{}
		for i in 0 .. n { if input[i + 1] < 32 || input[i + 1] > 126 { return -1 }; chars[i] = u8(input[i + 1]) }
		mut dp := [max_n * max_n]u16{}
		for span in 2 .. n + 1 {
			for left in 0 .. n - span + 1 {
				right := left + span - 1
				if chars[left] == chars[right] { if span > 2 { dp[left * max_n + right] = dp[(left + 1) * max_n + right - 1] } }
				else { a := dp[(left + 1) * max_n + right]; b := dp[left * max_n + right - 1]; dp[left * max_n + right] = if a < b { a + 1 } else { b + 1 } }
			}
		}
		insertions := int(dp[n - 1])
		palindrome_length := n + insertions
		mut palindrome := [2 * max_n - 1]u8{}
		mut left := 0
		mut right := n - 1
		mut out_left := 0
		mut out_right := palindrome_length - 1
		for left <= right {
			if chars[left] == chars[right] {
				palindrome[out_left] = chars[left]; palindrome[out_right] = chars[right]; left++
				if right == 0 { break }; right--
			} else if dp[(left + 1) * max_n + right] < dp[left * max_n + right - 1] {
				palindrome[out_left] = chars[left]; palindrome[out_right] = chars[left]; left++
			} else {
				palindrome[out_left] = chars[right]; palindrome[out_right] = chars[right]
				if right == 0 { break }; right--
			}
			out_left++; if out_right == 0 { break }; out_right--
		}
		mut payload := [max_output]u8{}
		mut written := write_i64(mut payload[0], 0, i64(insertions))
		written = write_i64(mut payload[0], written, i64(palindrome_length))
		for i in 0 .. palindrome_length { payload[written + i] = palindrome[i] }
		written += palindrome_length
		if output == nil || output_capacity < usize(written) { return -2 }
		for i in 0 .. written { output[i] = payload[i] }
		return i64(written)
	}
}
