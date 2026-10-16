package problem60

Max_Primes :: 1000
Target_Size :: 5
Pair_Cache_Size :: Max_Primes * Max_Primes

is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value == 2 || value == 3 do return true
	if value % 2 == 0 || value % 3 == 0 do return false
	for divisor := i64(5); divisor <= value / divisor; divisor += 6 {
		if value % divisor == 0 || value % (divisor + 2) == 0 do return false
	}
	return true
}

concatenate :: proc "contextless" (left, right: i64) -> i64 {
	scale := i64(10)
	for scale <= right { scale *= 10 }
	return left * scale + right
}

pair_works :: proc "contextless" (primes: [^]i64, cache: [^]u8,
								 left_index, right_index: int) -> bool {
	key := left_index * Max_Primes + right_index
	if cache[key] != 0 do return cache[key] == 2
	reverse_key := right_index * Max_Primes + left_index
	if cache[reverse_key] != 0 do return cache[reverse_key] == 2
	left := primes[left_index]
	right := primes[right_index]
	result := is_prime(concatenate(left, right)) && is_prime(concatenate(right, left))
	state := u8(1)
	if result do state = 2
	cache[key] = state
	cache[reverse_key] = state
	return result
}

search_set :: proc "contextless" (primes: [^]i64, prime_count: int, cache: [^]u8,
								 chain: [^]int, depth, start: int, sum: i64) -> i64 {
	if depth == Target_Size do return sum
	for index := start; index < prime_count; index += 1 {
		compatible := true
		for member := 0; member < depth; member += 1 {
			if !pair_works(primes, cache, index, chain[member]) {
				compatible = false
				break
			}
		}
		if !compatible do continue
		chain[depth] = index
		result := search_set(primes, prime_count, cache, chain, depth + 1,
							 index + 1, sum + primes[index])
		if result != 0 do return result
	}
	return 0
}

@(export)
problem60 :: proc "c" (placeholder: i64) -> i64 {
	if placeholder != 0 do return -1
	primes: [Max_Primes]i64
	primes[0] = 3
	primes[1] = 7
	primes[2] = 13
	primes[3] = 19
	prime_count := 4
	for prime_count < Max_Primes {
		candidate := primes[prime_count - 1] + 3
		for !is_prime(candidate) { candidate += 3 }
		primes[prime_count] = candidate
		prime_count += 1
	}
	cache: [Pair_Cache_Size]u8
	chain: [Target_Size]int
	for start := 0; start < prime_count; start += 1 {
		chain[0] = start
		result := search_set(&primes[0], prime_count, &cache[0], &chain[0],
							 1, start + 1, primes[start])
		if result != 0 do return result
	}
	return -1
}
