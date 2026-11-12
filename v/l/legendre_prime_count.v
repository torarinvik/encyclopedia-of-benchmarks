module legendre_prime_count

const max_input = i64(10000)

fn legendre_phi(primes []i64, value i64, count int) i64 {
	if value == 0 { return 0 }
	if count == 0 { return value }
	if count == 1 { return value - value / 2 }
	prime := primes[count - 1]
	if value < prime { return 1 }
	return legendre_phi(primes, value, count - 1) - legendre_phi(primes, value / prime, count - 1)
}

@[export: 'legendre_prime_count']
pub fn legendre_prime_count(value i64) i64 {
	if value < 0 || value > max_input { return -1 }
	if value < 2 { return 0 }
	mut root := i64(0)
	for (root + 1) * (root + 1) <= value { root++ }
	mut composite := [101]bool{}
	mut candidate := i64(2)
	for candidate * candidate <= root {
		if !composite[int(candidate)] {
			mut multiple := candidate * candidate
			for multiple <= root {
				composite[int(multiple)] = true
				multiple += candidate
			}
		}
		candidate++
	}
	mut primes := [25]i64{}
	mut count := 0
	candidate = 2
	for candidate <= root {
		if !composite[int(candidate)] {
			primes[count] = candidate
			count++
		}
		candidate++
	}
	return legendre_phi(primes[..count], value, count) + i64(count) - 1
}
