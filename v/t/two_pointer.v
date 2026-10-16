module two_pointer

@[export: 'two_pointer']
pub fn two_pointer(input &i64, length usize) i64 {
	if length < 2 || length > 258 { return -2 }
	n := input[0]; target := input[1]
	if n < 0 || n > 256 || length != usize(n + 2) || target < -2147483648 || target > 2147483647 { return -2 }
	for i in 0 .. int(n) { if input[i + 2] < -2147483648 || input[i + 2] > 2147483647 || (i > 0 && input[i + 1] > input[i + 2]) { return -2 } }
	mut left := 0; mut right := int(n) - 1
	for left < right { sum := input[left + 2] + input[right + 2]; if sum == target { return i64(left * 256 + right) }; if sum < target { left++ } else { right-- } }
	return -1
}
