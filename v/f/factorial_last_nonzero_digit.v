module factorial_last_nonzero_digit

const max_parseable_input_length = 2

fn digit_factor(digit i64) i64 {
	match digit {
		0, 1 { return 1 }
		2 { return 2 }
		3 { return 6 }
		else { return 4 }
	}
}

fn two_power_mod_10(exponent_mod_four i64) i64 {
	match exponent_mod_four {
		0 { return 1 }
		1 { return 2 }
		2 { return 4 }
		else { return 8 }
	}
}

@[export: 'factorial_last_nonzero_digit']
pub fn factorial_last_nonzero_digit(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_input_length {
		return -1
	}
	unsafe {
		if length != 1 || input[0] < 0 { return -1 }
		mut n := input[0]
		mut result := i64(1)
		for n >= 5 {
			quotient := n / 5
			remainder := n % 5
			result = result * digit_factor(remainder) % 10
			result = result * two_power_mod_10(quotient % 4) % 10
			n = quotient
		}
		return result * digit_factor(n) % 10
	}
}
