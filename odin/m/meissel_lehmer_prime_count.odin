package meissel_lehmer_prime_count

MAX_INPUT :: i64(100_000_000)
SIEVE_LIMIT :: 10_000
MAX_PRIMES :: 1_300
PHI_CACHE_X :: 2_048
PHI_CACHE_S :: 32

Prime_Count_Context :: struct {
	composite: [SIEVE_LIMIT + 1]bool,
	primes: [MAX_PRIMES]int,
	prime_count_prefix: [SIEVE_LIMIT + 1]int,
	phi_cache: [PHI_CACHE_S + 1][PHI_CACHE_X + 1]int,
}

integer_sqrt :: proc(value: u64) -> u64 {
	low: u64 = 0
	high := value + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle <= value / middle do low = middle else high = middle
	}
	return low
}

integer_cuberoot :: proc(value: u64) -> u64 {
	low: u64 = 0
	high := value + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle <= value / middle / middle do low = middle else high = middle
	}
	return low
}

phi :: proc(context: ^Prime_Count_Context, value: u64, prime_count: int) -> i64 {
	if value == 0 do return 0
	if prime_count == 0 do return i64(value)
	if prime_count == 1 do return i64(value - value / 2)
	prime := u64(context.primes[prime_count - 1])
	if value < prime do return 1
	if value <= PHI_CACHE_X && prime_count <= PHI_CACHE_S {
		x := int(value)
		cached := context.phi_cache[prime_count][x]
		if cached != 0 do return i64(cached)
		result := phi(context, value, prime_count - 1) - phi(context, value / prime, prime_count - 1)
		context.phi_cache[prime_count][x] = int(result)
		return result
	}
	return phi(context, value, prime_count - 1) - phi(context, value / prime, prime_count - 1)
}

lehmer_count :: proc(context: ^Prime_Count_Context, value: u64) -> i64 {
	if value <= SIEVE_LIMIT do return i64(context.prime_count_prefix[int(value)])
	a := context.prime_count_prefix[int(integer_sqrt(integer_sqrt(value)))]
	b := context.prime_count_prefix[int(integer_sqrt(value))]
	c := context.prime_count_prefix[int(integer_cuberoot(value))]
	result := phi(context, value, a) + i64((b + a - 2) * (b - a + 1) / 2)
	for i := a; i < b; i += 1 {
		quotient := value / u64(context.primes[i])
		result -= lehmer_count(context, quotient)
		if i < c {
			limit := int(lehmer_count(context, integer_sqrt(quotient)))
			for j := i; j < limit; j += 1 {
				result -= lehmer_count(context, quotient / u64(context.primes[j])) - i64(j)
			}
		}
	}
	return result
}

@(export, link_name="meissel_lehmer_prime_count")
meissel_lehmer_prime_count :: proc(value: i64) -> i64 {
	if value < 0 || value > MAX_INPUT do return -1
	context: Prime_Count_Context
	for candidate := 2; candidate * candidate <= SIEVE_LIMIT; candidate += 1 {
		if context.composite[candidate] do continue
		for multiple := candidate * candidate; multiple <= SIEVE_LIMIT; multiple += candidate {
			context.composite[multiple] = true
		}
	}
	prime_count := 0
	for candidate := 2; candidate <= SIEVE_LIMIT; candidate += 1 {
		if !context.composite[candidate] {
			context.primes[prime_count] = candidate
			prime_count += 1
		}
		context.prime_count_prefix[candidate] = context.prime_count_prefix[candidate - 1]
		if !context.composite[candidate] do context.prime_count_prefix[candidate] += 1
	}
	return lehmer_count(&context, u64(value))
}
