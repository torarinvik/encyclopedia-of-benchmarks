module powerful_number_summatory_sieve

const max_n = i64(1_000_000)
const max_root = 1_000
const max_primes = 168

struct PowerfulState {
mut:
	n i64
	total i64
	prime_count int
	primes [max_primes]i64
}

fn enumerate_powerful(mut state &PowerfulState, start int, current i64, current_h i64) {
	remaining := state.n / current
	mut prime_index := start
	for prime_index < state.prime_count {
		prime := state.primes[prime_index]
		if prime > remaining / prime { break }
		mut prime_power := prime * prime
		mut h_power := prime - 1
		for prime_power <= remaining {
			powerful := current * prime_power
			h_value := current_h * h_power
			state.total += h_value * (state.n / powerful)
			enumerate_powerful(mut state, prime_index + 1, powerful, h_value)
			if prime_power > remaining / prime { break }
			prime_power *= prime
			h_power *= prime
		}
		prime_index++
	}
}

fn solve(n i64) i64 {
	mut root := i64(1)
	for (root + 1) <= n / (root + 1) { root++ }
	mut composite := [max_root + 1]bool{}
	mut state := PowerfulState{n: n, total: n}
	mut candidate := 2
	for candidate <= int(root) {
		if !composite[candidate] {
			state.primes[state.prime_count] = i64(candidate)
			state.prime_count++
			if candidate <= int(root) / candidate {
				mut multiple := candidate * candidate
				for multiple <= int(root) {
					composite[multiple] = true
					multiple += candidate
				}
			}
		}
		candidate++
	}
	enumerate_powerful(mut state, 0, 1, 1)
	return state.total
}

@[export: 'powerful_number_summatory_sieve']
pub fn powerful_number_summatory_sieve(input &i64, length usize) i64 {
	if input == nil || length != 1 { return -1 }
	unsafe {
		n := input[0]
		if n < 1 || n > max_n { return -1 }
		return solve(n)
	}
}
