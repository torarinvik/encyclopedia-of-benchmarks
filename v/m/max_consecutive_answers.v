module max_consecutive_answers

const max_bits = 1024

fn max_length(a int, b int) int {
	if a > b { return a }
	return b
}

fn longest_for_target(input &i64, count int, allowed int, target i64) int {
	mut left := 0
	mut opposite := 0
	mut best := 0
	for right in 0 .. count {
		if unsafe { input[right + 1] != target } { opposite++ }
		for opposite > allowed {
			if unsafe { input[left + 1] != target } { opposite-- }
			left++
		}
		best = max_length(best, right - left + 1)
	}
	return best
}

@[export: 'max_consecutive_answers']
pub fn max_consecutive_answers(input &i64, length usize) i64 {
	if length == 0 || length > max_bits + 1 { return -1 }
	count := int(length) - 1
	if unsafe { input[0] < 0 || input[0] > i64(count) } { return -1 }
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value != 0 && value != 1 { return -1 }
	}
	allowed := int(unsafe { input[0] })
	return i64(max_length(longest_for_target(input, count, allowed, 1),
	                     longest_for_target(input, count, allowed, 0)))
}
