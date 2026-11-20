module hofstadter_q_sequence

const max_index = i64(128)
const max_parseable_length = usize(2)

@[export: 'hofstadter_q_sequence']
pub fn hofstadter_q_sequence(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		if length != 1 || input[0] < 1 || input[0] > max_index { return -1 }
		target := int(input[0])
		mut q := [129]i64{}
		q[1] = 1
		if target >= 2 { q[2] = 1 }
		for n := 3; n <= target; n++ {
			left := i64(n) - q[n - 1]
			right := i64(n) - q[n - 2]
			if left < 1 || right < 1 || left >= i64(n) || right >= i64(n) { return -1 }
			q[n] = q[int(left)] + q[int(right)]
		}
		return q[target]
	}
}
