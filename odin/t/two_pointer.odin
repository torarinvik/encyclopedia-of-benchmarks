package two_pointer

@(export, link_name="two_pointer")
two_pointer :: proc "c" (input: [^]i64, length: uint) -> i64 {
	if length < 2 || length > 258 do return -2
	n, target := input[0], input[1]
	if n < 0 || n > 256 || length != uint(n + 2) || target < -2147483648 || target > 2147483647 do return -2
	for i: i64 = 0; i < n; i += 1 { if input[i + 2] < -2147483648 || input[i + 2] > 2147483647 || (i > 0 && input[i + 1] > input[i + 2]) do return -2 }
	left, right: i64 = 0, n - 1
	for left < right { sum := input[left + 2] + input[right + 2]; if sum == target do return left * 256 + right; if sum < target { left += 1 } else { right -= 1 } }
	return -1
}
main :: proc() {}
