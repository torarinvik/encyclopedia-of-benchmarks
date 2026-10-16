module modpow
const invalid_result = i64(-9223372036854775807 - 1)
const max_parseable_input_length = 4
const max_component = i64(89000000)
const max_exponent = i64(64)
@[export: 'modpow']
pub fn modpow(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_parseable_input_length { return invalid_result }
	unsafe {
		if length != 3 { return invalid_result }
		mut base, mut exponent := input[0], input[1]
		modulus := input[2]
		if base < 0 || base > max_component || exponent < 0 || exponent > max_exponent { return invalid_result }
		if modulus < 1 || modulus > max_component { return invalid_result }
		if exponent == 0 {
			if base == 0 { return invalid_result }
			return 1 % modulus
		}
		if base == 0 { return 0 }
		mut result := i64(1) % modulus
		for exponent > 0 {
			if exponent % 2 == 1 {
				result = (result * base) % modulus
				exponent--
			} else {
				base = (base * base) % modulus
				exponent /= 2
			}
		}
		return result
	}
}
