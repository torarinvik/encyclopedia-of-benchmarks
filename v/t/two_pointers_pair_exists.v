module two_pointers_pair_exists

@[export: 'two_pointers_pair_exists']
pub fn two_pointers_pair_exists(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 258 { return -1 }
	target := unsafe { input[0] }
	n := unsafe { input[1] }
	if n < 0 || n > 256 || length != usize(2 + n) { return -1 }
	if target < -2000000 || target > 2000000 { return -1 }
	for i in 0 .. int(n) {
		value := unsafe { input[2 + i] }
		if value < -1000000 || value > 1000000 { return -1 }
		if i > 0 && unsafe { input[1 + i] > value } { return -1 }
	}
	if n < 2 { return 0 }
	mut left := 0
	mut right := int(n) - 1
	for left < right {
		sum := unsafe { input[2 + left] + input[2 + right] }
		if sum == target { return 1 }
		if sum < target { left++ } else { right-- }
	}
	return 0
}
