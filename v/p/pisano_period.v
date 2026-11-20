module pisano_period

const max_modulus = i64(64)
const max_input_length = 2

@[export: 'pisano_period']
pub fn pisano_period(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		if length != 1 || input[0] < 1 || input[0] > max_modulus { return -1 }
		modulus := input[0]
		initial_next := i64(1) % modulus
		mut previous := i64(0)
		mut current := initial_next
		for period := i64(1); period <= 6 * modulus; period++ {
			next := (previous + current) % modulus
			previous = current
			current = next
			if previous == 0 && current == initial_next { return period }
		}
		return -1
	}
}
