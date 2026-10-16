module problem50

@[export: 'problem50']
pub fn problem50(ceiling i64) i64 {
	if ceiling < 3 || ceiling > 1000000 { return -1 }
	limit := int(ceiling)
	mut is_prime := [1000000]bool{}
	for index in 0..limit { is_prime[index] = true }
	is_prime[0] = false
	is_prime[1] = false
	mut value := 2
	for value <= (limit - 1) / value {
		if is_prime[value] {
			mut multiple := value * value
			for multiple < limit {
				is_prime[multiple] = false
				multiple += value
			}
		}
		value++
	}
	mut primes := [100000]int{}
	mut prime_count := 0
	for candidate in 2..limit {
		if is_prime[candidate] {
			primes[prime_count] = candidate
			prime_count++
		}
	}
	mut longest := 0
	mut largest := i64(0)
	for start := 0; start < prime_count; start++ {
		end_start := start + longest
		mut end := start
		mut sum := i64(0)
		for finish := end_start; finish < prime_count; finish++ {
			for end < finish {
				sum += i64(primes[end])
				end++
			}
			if sum >= ceiling { break }
			if is_prime[int(sum)] {
				longest = finish - start
				largest = sum
			}
		}
	}
	return largest
}
