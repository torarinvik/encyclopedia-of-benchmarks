module longest_common_increasing_subsequence

@[export: 'longest_common_increasing_subsequence']
pub fn longest_common_increasing_subsequence(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 67 { return -1 }
	unsafe {
		n := input[0]
		m := input[1]
		if n < 0 || n > 32 || m < 0 || m > 32 || length != usize(2 + n + m) { return -1 }
		for index in 0 .. usize(n + m) {
			if input[2 + index] < -16 || input[2 + index] > 16 { return -1 }
		}
		mut ending_at := [32]i64{init: 0}
		for i in 0 .. usize(n) {
			value := input[2 + i]
			mut best_smaller := i64(0)
			for j in 0 .. usize(m) {
				other := input[2 + usize(n) + j]
				if value > other {
					if ending_at[j] > best_smaller { best_smaller = ending_at[j] }
				} else if value == other && best_smaller + 1 > ending_at[j] {
					ending_at[j] = best_smaller + 1
				}
			}
		}
		mut answer := i64(0)
		for j in 0 .. usize(m) { if ending_at[j] > answer { answer = ending_at[j] } }
		return answer
	}
}
