module sieve_of_eratosthenes

// Count the primes through limit using the Sieve of Eratosthenes.
@[export: 'sieve_of_eratosthenes']
pub fn sieve_of_eratosthenes(limit i64) i64 {
	if limit < 0 || limit > 4096 { return -1 }
	if limit < 2 { return 0 }
	mut prime := [4097]bool{init: false}
	for value in 2 .. int(limit) + 1 { prime[value] = true }
	mut factor := 2
	for factor * factor <= int(limit) {
		if prime[factor] {
			mut multiple := factor * factor
			for multiple <= int(limit) {
				prime[multiple] = false
				multiple += factor
			}
		}
		factor++
	}
	mut count := i64(0)
	for value in 2 .. int(limit) + 1 {
		if prime[value] { count++ }
	}
	return count
}
