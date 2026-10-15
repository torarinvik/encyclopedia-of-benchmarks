module min_number_of_jumps

const max_length = 64
const unreachable = i64(1_000_000_000_000)

@[export: 'min_number_of_jumps']
pub fn min_number_of_jumps(values &i64, length usize) i64 {
	if length < 1 || length > max_length || unsafe { values == nil } { return -1 }
	unsafe {
		for i := usize(0); i < length; i++ {
			if values[i] < 0 || values[i] > max_length { return -1 }
		}
		mut jumps := [64]i64{}
		for i in 0 .. max_length { jumps[i] = unreachable }
		jumps[0] = 0
		for i := 1; i < int(length); i++ {
			for j := 0; j < i; j++ {
				if values[j] + i64(j) >= i64(i) && jumps[j] + 1 < jumps[i] { jumps[i] = jumps[j] + 1 }
			}
		}
		return jumps[int(length) - 1]
	}
}
