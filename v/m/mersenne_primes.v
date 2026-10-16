@[export: 'mersenne_primes']
pub fn mersenne_primes(n i64) i64 {
	if n < 2 || n > 31 { return -1 }
	if n == 2 { return 1 }
	modulus := (i64(1) << n) - 1
	mut residue := i64(4)
	for _ in 0 .. int(n - 2) {
		residue = (residue * residue - 2) % modulus
	}
	if residue == 0 { return 1 }
	return 0
}
