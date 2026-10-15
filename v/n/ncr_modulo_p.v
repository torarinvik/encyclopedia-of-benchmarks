module ncr_modulo_p

const invalid_result = i64(-9223372036854775807 - 1)

fn inverse(a i64, m i64) i64 {
	mut old_r := a
	mut r := m
	mut old_s := i64(1)
	mut s := i64(0)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r - quotient * r
		next_s := old_s - quotient * s
		old_r = r
		r = next_r
		old_s = s
		s = next_s
	}
	return if old_r == 1 { (old_s + m) % m } else { -1 }
}

@[export: 'ncr_modulo_p']
pub fn ncr_modulo_p(values &i64, length usize) i64 {
	if length != 4 { return invalid_result }
	unsafe {
		size := values[0]
		p := values[1]
		n := values[2]
		r := values[3]
		if size < 0 || size > 64 || p < 2 || p > 1009 || n < 0 || n > size || r < 0 || r > 64 {
			return invalid_result
		}
		mut fac := [65]i64{}
		fac[0] = 1
		for i := i64(1); i <= size; i++ { fac[i] = (fac[i - 1] * i) % p }
		if r > n { return 0 }
		if r == 1 { return n % p }
		if r == 0 || r == n { return 1 }
		denominator := (fac[r] * fac[n - r]) % p
		denominator_inv := inverse(denominator, p)
		if denominator_inv < 0 { return -1 }
		return (fac[n] * denominator_inv) % p
	}
}
