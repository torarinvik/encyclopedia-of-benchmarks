module dedekind_sum_reciprocity

const max_modulus = i64(100_000)
const result_offset = i64(29_999_700_001)

fn gcd(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn scaled_sum(numerator i64, modulus i64) i64 {
	if modulus == 1 { return 0 }
	tail := scaled_sum(modulus % numerator, numerator)
	top := numerator*numerator + modulus*modulus + 1 - 3*numerator*modulus - modulus*tail
	return top/numerator
}

@[export: 'dedekind_sum_reciprocity']
pub fn dedekind_sum_reciprocity(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		numerator := input[0]
		modulus := input[1]
		if modulus < 1 || modulus > max_modulus || numerator < 0 || numerator >= modulus { return -1 }
		if gcd(numerator, modulus) != 1 { return -1 }
		return result_offset + scaled_sum(numerator, modulus)
	}
}
