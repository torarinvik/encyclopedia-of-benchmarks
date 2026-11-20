package strong_weak_balanced_prime_distribution

import "core:c"

MAX_LIMIT :: 100_000

@(export)
strong_weak_balanced_prime_distribution :: proc(input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 2 do return -1
	limit := input[0]
	if length != 1 || limit < 3 || limit > MAX_LIMIT do return -1

	ceiling := 2 * limit
	prime: [200001]bool
	for index := 0; index < len(prime); index += 1 do prime[index] = true
	prime[0] = false
	prime[1] = false
	for divisor := i64(2); divisor * divisor <= ceiling; divisor += 1 {
		if !prime[divisor] do continue
		for multiple := divisor * divisor; multiple <= ceiling; multiple += divisor {
			prime[multiple] = false
		}
	}

	strong, weak, balanced := i64(0), i64(0), i64(0)
	previous, current := i64(0), i64(0)
	for candidate := i64(2); candidate <= ceiling; candidate += 1 {
		if !prime[candidate] do continue
		if previous != 0 && current >= 3 && current <= limit {
			twice, neighbors := 2 * current, previous + candidate
			if twice > neighbors do strong += 1
			else if twice < neighbors do weak += 1
			else do balanced += 1
		}
		previous, current = current, candidate
	}
	return strong * 10_000_000_000 + weak * 100_000 + balanced
}
