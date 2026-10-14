package sieve_of_eratosthenes

// Count the primes through limit using the Sieve of Eratosthenes.
@(export)
sieve_of_eratosthenes :: proc "c" (limit: i64) -> i64 {
	if limit < 0 || limit > 4096 do return -1
	prime: [4097]bool
	for value := 0; value < len(prime); value += 1 {
		prime[value] = false
	}
	for value := 2; i64(value) <= limit; value += 1 {
		prime[value] = true
	}
	for factor := 2; i64(factor) <= limit / i64(factor); factor += 1 {
		if prime[factor] {
			for multiple := factor * factor; i64(multiple) <= limit; multiple += factor {
				prime[multiple] = false
			}
		}
	}
	count := i64(0)
	for value := 2; i64(value) <= limit; value += 1 {
		if prime[value] do count += 1
	}
	return count
}
