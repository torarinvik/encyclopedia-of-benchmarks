module sieve

const sieve_limit = 8192
const max_iterations = 64

@[export: 'sieve']
pub fn sieve(iterations i64, mut output &u8, output_capacity usize) i64 {
	if iterations < 0 || iterations > max_iterations {
		return -1
	}

	mut flags := [8193]u8{}
	mut count := i64(0)
	for _ in 0 .. int(iterations) {
		count = 0
		for value := 2; value <= sieve_limit; value++ {
			flags[value] = 1
		}
		for value := 2; value <= sieve_limit; value++ {
			if flags[value] != 0 {
				count++
				mut multiple := value + value
				for multiple <= sieve_limit {
					flags[multiple] = 0
					multiple += value
				}
			}
		}
	}

	mut reversed_digits := [10]u8{}
	mut digit_count := 0
	mut remaining := count
	for {
		reversed_digits[digit_count] = u8(48 + remaining % 10)
		digit_count++
		remaining /= 10
		if remaining == 0 {
			break
		}
	}
	required := 8 + digit_count
	if output == nil || output_capacity < required {
		return -2
	}
	unsafe {
		output[0] = 67; output[1] = 111; output[2] = 117
		output[3] = 110; output[4] = 116; output[5] = 58
		output[6] = 32
		for index in 0 .. digit_count {
			output[7 + index] = reversed_digits[digit_count - index - 1]
		}
		output[required - 1] = 10
	}
	return i64(required)
}
