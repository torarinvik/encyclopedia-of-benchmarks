package problem50

@(export)
problem50 :: proc "c" (ceiling: i64) -> i64 {
	if ceiling < 3 || ceiling > 1_000_000 do return -1
	limit := int(ceiling)
	is_prime: [1_000_000]bool
	for index := 0; index < limit; index += 1 { is_prime[index] = true }
	is_prime[0] = false
	is_prime[1] = false
	for value := 2; value <= (limit - 1) / value; value += 1 {
		if !is_prime[value] do continue
		for multiple := value * value; multiple < limit; multiple += value { is_prime[multiple] = false }
	}
	primes: [100_000]int
	prime_count := 0
	for candidate := 2; candidate < limit; candidate += 1 {
		if is_prime[candidate] { primes[prime_count] = candidate; prime_count += 1 }
	}
	longest := 0
	largest := i64(0)
	for start := 0; start < prime_count; start += 1 {
		end_start := start + longest
		end := start
		sum := i64(0)
		for finish := end_start; finish < prime_count; finish += 1 {
			for end < finish { sum += i64(primes[end]); end += 1 }
			if sum >= ceiling do break
			if is_prime[int(sum)] {
				longest = finish - start
				largest = sum
			}
		}
	}
	return largest
}
