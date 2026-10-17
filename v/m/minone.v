module minone

const max_length = 64
const min_value = i64(-1_000_000)
const max_value = i64(1_000_000)

@[export: 'minone']
pub fn minone(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_length { return -1 }
	unsafe {
		mut total := i64(0)
		for index in 0 .. int(length) {
			value := input[index]
			if value < min_value || value > max_value { return -1 }
			total += value * value
		}
		return total
	}
}
