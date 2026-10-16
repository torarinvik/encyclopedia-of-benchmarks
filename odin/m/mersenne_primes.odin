package mersenne_primes

@(export)
mersenne_primes :: proc "contextless" (n: i64) -> i64 {
	if n < 2 || n > 31 do return -1
	if n == 2 do return 1
	modulus := (i64(1) << u6(n)) - 1
	residue := i64(4)
	for round := i64(0); round < n - 2; round += 1 {
		residue = (residue * residue - 2) % modulus
	}
	if residue == 0 do return 1
	return 0
}
