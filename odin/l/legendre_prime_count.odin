package legendre_prime_count

MAX_INPUT :: i64(10000)

legendre_phi :: proc(primes: []i64, value: i64, count: int) -> i64 {
	if value == 0 do return 0
	if count == 0 do return value
	if count == 1 do return value - value / 2
	prime := primes[count - 1]
	if value < prime do return 1
	return legendre_phi(primes, value, count - 1) - legendre_phi(primes, value / prime, count - 1)
}

@(export, link_name="legendre_prime_count")
legendre_prime_count :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > MAX_INPUT do return -1
	if value < 2 do return 0
	root: i64 = 0
	for (root + 1) * (root + 1) <= value { root += 1 }
	composite: [101]bool = {}
	for candidate: i64 = 2; candidate * candidate <= root; candidate += 1 {
		if composite[candidate] do continue
		for multiple := candidate * candidate; multiple <= root; multiple += candidate {
			composite[multiple] = true
		}
	}
	primes: [25]i64
	count := 0
	for candidate: i64 = 2; candidate <= root; candidate += 1 {
		if !composite[candidate] {
			primes[count] = candidate
			count += 1
		}
	}
	return legendre_phi(primes[:count], value, count) + i64(count) - 1
}

main :: proc() {}
