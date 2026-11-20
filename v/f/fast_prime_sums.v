module fast_prime_sums

const sieve_limit = 32000
const prime_capacity = 3500
const phi_rows = 12
const phi_columns = 30000
const max_input = i64(1000000000)

struct PrimeSumContext {
	composite [sieve_limit + 1]bool
	primes [prime_capacity]i64
	prime_count [sieve_limit + 1]int
	prime_sum [sieve_limit + 1]i64
	phi [phi_rows * phi_columns]i64
}

fn sqrt_floor(n i64) i64 {
	mut low := i64(0)
	mut high := n + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle <= n / middle { low = middle } else { high = middle }
	}
	return low
}

fn cbrt_floor(n i64) i64 {
	mut low := i64(0)
	mut high := i64(1)
	for high * high * high <= n { high *= 2 }
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle * middle * middle <= n { low = middle } else { high = middle }
	}
	return low
}

fn weighted_phi(mut context PrimeSumContext, n i64, count int) i64 {
	if n <= 0 { return 0 }
	if count == 0 { return n * (n + 1) / 2 }
	prime := context.primes[count - 1]
	if n <= prime { return 1 }
	if count < phi_rows && n < i64(phi_columns) { return context.phi[count * phi_columns + int(n)] }
	if n < i64(sieve_limit) && prime * prime >= n {
	return context.prime_sum[int(n)] - context.prime_sum[int(prime)] + 1
	}
	if n < i64(sieve_limit) && prime * prime * prime >= n {
		mut total := context.prime_sum[int(n)] - context.prime_sum[int(prime)] + 1
		limit := context.prime_count[int(sqrt_floor(n))]
		for index := count; index < limit; index++ {
			other := context.primes[index]
			total += other * (context.prime_sum[int(n / other)] - context.prime_sum[int(other - 1)])
		}
		return total
	}
	return weighted_phi(mut context, n, count - 1) - prime * weighted_phi(mut context, n / prime, count - 1)
}

fn sum_primes(mut context PrimeSumContext, n i64) i64 {
	if n <= sieve_limit { return context.prime_sum[int(n)] }
	cube := int(cbrt_floor(n))
	square := int(sqrt_floor(n))
	first := context.prime_count[cube]
	last := context.prime_count[square]
	mut total := weighted_phi(mut context, n, first) + context.prime_sum[cube] - 1
	for index := first; index < last; index++ {
		prime := context.primes[index]
		quotient := n / prime
		total -= (sum_primes(mut context, quotient) - context.prime_sum[int(prime - 1)]) * prime
	}
	return total
}

@[export: 'fast_prime_sums']
pub fn fast_prime_sums(value i64) i64 {
	if value < 0 || value > max_input { return -1 }
	mut context := PrimeSumContext{}
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
	mut count := 0
	for n in 2 .. sieve_limit + 1 {
		if !context.composite[n] {
			context.primes[count] = i64(n)
			count++
		}
		context.prime_count[n] = context.prime_count[n - 1]
		context.prime_sum[n] = context.prime_sum[n - 1]
		if !context.composite[n] {
			context.prime_count[n]++
			context.prime_sum[n] += i64(n)
		}
	}
	for n in 0 .. phi_columns { context.phi[n] = i64(n) * i64(n + 1) / 2 }
	for row in 1 .. phi_rows {
		prime := context.primes[row - 1]
		previous := (row - 1) * phi_columns
		current := row * phi_columns
		for n in 0 .. phi_columns {
			context.phi[current + n] = context.phi[previous + n] - prime * context.phi[previous + n / int(prime)]
		}
	}
	return sum_primes(mut context, value)
}
