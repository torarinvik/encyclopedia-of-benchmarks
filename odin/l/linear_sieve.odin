package linear_sieve

// Count primes through limit with the linear (Euler) sieve.
@(export)
linear_sieve :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 4096 do return -1
	if limit < 2 do return 0
	state: [4662]i64
	for index := 0; index < 4662; index += 1 { state[index] = 0 }
	for value := 2; i64(value) <= limit; value += 1 {
		if state[value] == 0 {
			state[value] = i64(value)
			state[4097 + int(state[4661])] = i64(value)
			state[4661] += 1
		}
		for index := 0; i64(index) < state[4661]; index += 1 {
			prime := state[4097 + index]
			if prime > state[value] || prime > limit / i64(value) { break }
			state[int(i64(value) * prime)] = prime
		}
	}
	return state[4661]
}
