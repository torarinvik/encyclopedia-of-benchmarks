module problem60

const max_primes = 1000
const target_size = 5

fn is_prime(value i64) bool {
	if value < 2 { return false }
	if value == 2 || value == 3 { return true }
	if value % 2 == 0 || value % 3 == 0 { return false }
	mut divisor := i64(5)
	for divisor <= value / divisor {
		if value % divisor == 0 || value % (divisor + 2) == 0 { return false }
		divisor += 6
	}
	return true
}

fn concatenate(left i64, right i64) i64 {
	mut scale := i64(10)
	for scale <= right { scale *= 10 }
	return left * scale + right
}

fn pair_works(primes []i64, mut cache []u8, left_index int, right_index int) bool {
	key := left_index * max_primes + right_index
	if cache[key] != 0 { return cache[key] == 2 }
	reverse_key := right_index * max_primes + left_index
	if cache[reverse_key] != 0 { return cache[reverse_key] == 2 }
	left := primes[left_index]
	right := primes[right_index]
	result := is_prime(concatenate(left, right)) && is_prime(concatenate(right, left))
	state := u8(1)
	if result { state = 2 }
	cache[key] = state
	cache[reverse_key] = state
	return result
}

fn search_set(primes []i64, mut cache []u8, mut chain []int,
			  depth int, start int, sum i64) i64 {
	if depth == target_size { return sum }
	for candidate := start; candidate < primes.len; candidate++ {
		mut compatible := true
		for member := 0; member < depth; member++ {
			if !pair_works(primes, mut cache, candidate, chain[member]) {
				compatible = false
				break
			}
		}
		if !compatible { continue }
		chain[depth] = candidate
		result := search_set(primes, mut cache, mut chain, depth + 1,
							 candidate + 1, sum + primes[candidate])
		if result != 0 { return result }
	}
	return 0
}

@[export: 'problem60']
pub fn problem60(placeholder i64) i64 {
	if placeholder != 0 { return -1 }
	mut primes := []i64{cap: max_primes}
	primes << 3
	primes << 7
	primes << 13
	primes << 19
	for primes.len < max_primes {
		mut candidate := primes[primes.len - 1] + 3
		for !is_prime(candidate) { candidate += 3 }
		primes << candidate
	}
	mut cache := []u8{len: max_primes * max_primes, init: 0}
	mut chain := []int{len: target_size, init: 0}
	for start in 0 .. primes.len {
		chain[0] = start
		result := search_set(primes, mut cache, mut chain, 1, start + 1, primes[start])
		if result != 0 { return result }
	}
	return -1
}
