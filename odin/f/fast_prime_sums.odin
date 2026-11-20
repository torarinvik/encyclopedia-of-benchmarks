package fast_prime_sums

SIEVE_LIMIT :: 32_000
PHI_ROWS :: 12
PHI_COLUMNS :: 30_000
MAX_INPUT :: i64(1_000_000_000)

Prime_Sum_Context :: struct {
	primes: []i64,
	prime_count: []int,
	prime_sum: []i64,
	phi: []i64,
}

sqrt_floor :: proc(n: i64) -> i64 {
	low: i64 = 0
	high := n + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle <= n / middle do low = middle else high = middle
	}
	return low
}

cbrt_floor :: proc(n: i64) -> i64 {
	low: i64 = 0
	high: i64 = 1
	for high * high * high <= n do high *= 2
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle * middle * middle <= n do low = middle else high = middle
	}
	return low
}

build_context :: proc() -> Prime_Sum_Context {
	context := Prime_Sum_Context{
		primes = make([]i64, 0, 3500),
		prime_count = make([]int, SIEVE_LIMIT + 1),
		prime_sum = make([]i64, SIEVE_LIMIT + 1),
		phi = make([]i64, PHI_ROWS * PHI_COLUMNS),
	}
	composite := make([]bool, SIEVE_LIMIT + 1)
	defer delete(composite)
	for candidate := 2; candidate*candidate <= SIEVE_LIMIT; candidate += 1 {
		if composite[candidate] do continue
		for multiple := candidate*candidate; multiple <= SIEVE_LIMIT; multiple += candidate {
			composite[multiple] = true
		}
	}
	for candidate := 2; candidate <= SIEVE_LIMIT; candidate += 1 {
		if !composite[candidate] do append(&context.primes, i64(candidate))
		context.prime_count[candidate] = context.prime_count[candidate-1]
		context.prime_sum[candidate] = context.prime_sum[candidate-1]
		if !composite[candidate] {
			context.prime_count[candidate] += 1
			context.prime_sum[candidate] += i64(candidate)
		}
	}
	for n := 0; n < PHI_COLUMNS; n += 1 {
		context.phi[n] = i64(n) * i64(n+1) / 2
	}
	for row := 1; row < PHI_ROWS; row += 1 {
		prime := context.primes[row-1]
		previous := (row - 1) * PHI_COLUMNS
		current := row * PHI_COLUMNS
		for n := 0; n < PHI_COLUMNS; n += 1 {
			context.phi[current+n] = context.phi[previous+n] - prime*context.phi[previous+n/int(prime)]
		}
	}
	return context
}

weighted_phi :: proc(context: ^Prime_Sum_Context, n: i64, count: int) -> i64 {
	if n <= 0 do return 0
	if count == 0 do return n * (n + 1) / 2
	prime := context.primes[count-1]
	if n <= prime do return 1
	if count < PHI_ROWS && n < PHI_COLUMNS {
		return context.phi[count*PHI_COLUMNS+int(n)]
	}
	if n < SIEVE_LIMIT && prime*prime >= n do return context.prime_sum[int(n)] - context.prime_sum[int(prime)] + 1
	if n < SIEVE_LIMIT && prime*prime*prime >= n {
		result := context.prime_sum[int(n)] - context.prime_sum[int(prime)] + 1
		limit := context.prime_count[int(sqrt_floor(n))]
		for i := count; i < limit; i += 1 {
			other := context.primes[i]
			result += other * (context.prime_sum[int(n/other)] - context.prime_sum[int(other-1)])
		}
		return result
	}
	return weighted_phi(context, n, count-1) - prime*weighted_phi(context, n/prime, count-1)
}

sum_primes :: proc(context: ^Prime_Sum_Context, n: i64) -> i64 {
	if n <= SIEVE_LIMIT do return context.prime_sum[int(n)]
	cube := int(cbrt_floor(n))
	square := int(sqrt_floor(n))
	first := context.prime_count[cube]
	last := context.prime_count[square]
	result := weighted_phi(context, n, first) + context.prime_sum[cube] - 1
	for i := first; i < last; i += 1 {
		prime := context.primes[i]
		quotient := n / prime
		result -= (sum_primes(context, quotient) - context.prime_sum[int(prime-1)]) * prime
	}
	return result
}

@(export)
fast_prime_sums :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > MAX_INPUT do return -1
	context := build_context()
	defer delete(context.primes)
	defer delete(context.prime_count)
	defer delete(context.prime_sum)
	defer delete(context.phi)
	return sum_primes(&context, value)
}
