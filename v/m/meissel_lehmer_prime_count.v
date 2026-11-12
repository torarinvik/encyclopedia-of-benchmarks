module meissel_lehmer_prime_count

const max_input = i64(100_000_000)
const sieve_limit = 10_000
const max_primes = 1_300
const phi_cache_x = 2_048
const phi_cache_s = 32

struct PrimeCountContext {
	composite [sieve_limit + 1]bool
	primes [max_primes]int
	prime_count_prefix [sieve_limit + 1]int
	phi_cache [phi_cache_s + 1][phi_cache_x + 1]int
}

fn integer_sqrt(value u64) u64 {
	mut low := u64(0)
	mut high := value + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle <= value / middle { low = middle } else { high = middle }
	}
	return low
}

fn integer_cuberoot(value u64) u64 {
	mut low := u64(0)
	mut high := value + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle <= value / middle / middle { low = middle } else { high = middle }
	}
	return low
}

fn phi(mut context PrimeCountContext, value u64, prime_count int) i64 {
	if value == 0 { return 0 }
	if prime_count == 0 { return i64(value) }
	if prime_count == 1 { return i64(value - value / 2) }
	prime := u64(context.primes[prime_count - 1])
	if value < prime { return 1 }
	if value <= phi_cache_x && prime_count <= phi_cache_s {
		x := int(value)
		cached := context.phi_cache[prime_count][x]
		if cached != 0 { return i64(cached) }
		result := phi(mut context, value, prime_count - 1) - phi(mut context, value / prime, prime_count - 1)
		context.phi_cache[prime_count][x] = int(result)
		return result
	}
	return phi(mut context, value, prime_count - 1) - phi(mut context, value / prime, prime_count - 1)
}

fn lehmer_count(mut context PrimeCountContext, value u64) i64 {
	if value <= sieve_limit { return i64(context.prime_count_prefix[int(value)]) }
	a := context.prime_count_prefix[int(integer_sqrt(integer_sqrt(value)))]
	b := context.prime_count_prefix[int(integer_sqrt(value))]
	c := context.prime_count_prefix[int(integer_cuberoot(value))]
	mut result := phi(mut context, value, a) + i64((b + a - 2) * (b - a + 1) / 2)
	for i in a .. b {
		quotient := value / u64(context.primes[i])
		result -= lehmer_count(mut context, quotient)
		if i < c {
			limit := int(lehmer_count(mut context, integer_sqrt(quotient)))
			for j in i .. limit {
				result -= lehmer_count(mut context, quotient / u64(context.primes[j])) - i64(j)
			}
		}
	}
	return result
}

@[export: 'meissel_lehmer_prime_count']
pub fn meissel_lehmer_prime_count(value i64) i64 {
	if value < 0 || value > max_input { return -1 }
	mut context := PrimeCountContext{}
	for candidate in 2 .. sieve_limit + 1 {
		if context.composite[candidate] { continue }
		if candidate <= sieve_limit / candidate {
			mut multiple := candidate * candidate
			for multiple <= sieve_limit {
				context.composite[multiple] = true
				multiple += candidate
			}
		}
	}
	mut prime_count := 0
	for candidate in 2 .. sieve_limit + 1 {
		if !context.composite[candidate] {
			context.primes[prime_count] = candidate
			prime_count++
		}
		context.prime_count_prefix[candidate] = context.prime_count_prefix[candidate - 1]
		if !context.composite[candidate] { context.prime_count_prefix[candidate]++ }
	}
	return lehmer_count(mut context, u64(value))
}
