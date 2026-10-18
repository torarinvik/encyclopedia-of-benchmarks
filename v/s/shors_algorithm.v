module shors_algorithm

const min_modulus = i64(2)
const max_modulus = i64(255)
const min_attempts = i64(1)
const max_attempts = i64(16)
const invalid_result = i64(-1)

fn gcd_i64(a_input i64, b_input i64) i64 {
	mut a := a_input
	mut b := b_input
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

@[export: 'shors_algorithm']
pub fn shors_algorithm(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 3 || length > 19 { return invalid_result }
	modulus := unsafe { packed[0] }
	attempts := unsafe { packed[1] }
	if modulus < min_modulus || modulus > max_modulus || attempts < min_attempts || attempts > max_attempts || length != usize(2 + attempts) { return invalid_result }
	for index in 0 .. int(attempts) {
		base := unsafe { packed[2 + index] }
		if base < 2 || base > modulus { return invalid_result }
	}

	for index in 0 .. int(attempts) {
		base := unsafe { packed[2 + index] }
		common := gcd_i64(base, modulus)
		if common != 1 { return common }
		mut order := i64(1)
		mut power := base % modulus
		for power != 1 && order < modulus - 1 {
			power = (power * base) % modulus
			order++
		}
		if power != 1 { return invalid_result }
		if order % 2 == 1 { continue }

		mut half_power := i64(1)
		for _ in 0 .. int(order / 2) {
			half_power = (half_power * base) % modulus
		}
		upper := half_power + 1
		lower := half_power - 1
		if upper % modulus == 0 || lower % modulus == 0 { continue }
		upper_gcd := gcd_i64(upper, modulus)
		if upper_gcd != 1 { return upper_gcd }
		return gcd_i64(lower, modulus)
	}
	return invalid_result
}
