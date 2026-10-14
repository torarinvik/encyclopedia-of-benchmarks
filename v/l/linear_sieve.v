module linear_sieve

// Count primes through limit with the linear (Euler) sieve.
@[export: 'linear_sieve']
pub fn linear_sieve(limit i64) i64 {
	if limit < 0 || limit > 4096 { return -1 }
	if limit < 2 { return 0 }
	mut state := [4662]i64{init: 0}
	for value in 2 .. int(limit) + 1 {
		if state[value] == 0 {
			state[value] = i64(value)
			count := int(state[4661])
			state[4097 + count] = i64(value)
			state[4661]++
		}
		mut index := 0
		for index < int(state[4661]) {
			prime := state[4097 + index]
			if prime > state[value] || prime > limit / i64(value) { break }
			state[int(i64(value) * prime)] = prime
			index++
		}
	}
	return state[4661]
}
