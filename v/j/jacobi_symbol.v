module jacobi_symbol

const max_modulus = i64(1_000_000_000)

fn reciprocity(numerator i64, denominator i64) i64 {
	mut a := numerator
	mut n := denominator
	mut sign := i64(1)
	for a != 0 {
		for (a & 1) == 0 {
			a /= 2
			if n % 8 == 3 || n % 8 == 5 { sign = -sign }
		}
		if a % 4 == 3 && n % 4 == 3 { sign = -sign }
		old_a := a
		a = n
		n = old_a
		a %= n
	}
	if n == 1 { return sign }
	return 0
}

@[export: 'jacobi_symbol']
pub fn jacobi_symbol(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		numerator := input[0]
		denominator := input[1]
		if denominator < 1 || denominator > max_modulus || (denominator & 1) == 0 { return -1 }
		if numerator < 0 || numerator >= denominator { return -1 }
		return reciprocity(numerator, denominator) + 1
	}
}
