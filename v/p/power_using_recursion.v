module power_using_recursion

fn power_using_recursion_value(base i64, exponent i64) i64 {
	if exponent == 0 { return 1 }
	return base * power_using_recursion_value(base, exponent - 1)
}

@[export: 'power_using_recursion']
pub fn power_using_recursion(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		base, exponent := input[0], input[1]
		if base < -10 || base > 10 || exponent < 0 || exponent > 15 { return -1 }
		return power_using_recursion_value(base, exponent)
	}
}
