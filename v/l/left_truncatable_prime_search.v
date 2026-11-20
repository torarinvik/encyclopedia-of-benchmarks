module left_truncatable_prime_search

const max_limit = i64(100_000)
const max_queue = 70_000

fn is_prime(value i64) bool {
	if value < 2 { return false }
	if value % 2 == 0 { return value == 2 }
	mut divisor := i64(3)
	for divisor * divisor <= value {
		if value % divisor == 0 { return false }
		divisor += 2
	}
	return true
}

fn search(base i64, digits i64) i64 {
	mut queue := [max_queue]i64{}
	mut end := 0
	for value := i64(2); value < base; value++ {
		if is_prime(value) {
			queue[end] = value
			end++
		}
	}
	mut best := queue[end - 1]
	mut level_start := 0
	mut level_end := end
	mut place := base
	for mut width := i64(1); width < digits && level_start < level_end; width++ {
		for index := level_start; index < level_end; index++ {
			suffix := queue[index]
			for leading := i64(1); leading < base; leading++ {
				candidate := leading * place + suffix
				if is_prime(candidate) {
					if end >= max_queue { return -1 }
					queue[end] = candidate
					end++
					if candidate > best { best = candidate }
				}
			}
		}
		level_start = level_end
		level_end = end
		place *= base
	}
	return best
}

@[export: 'left_truncatable_prime_search']
pub fn left_truncatable_prime_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 3 { return -1 }
		base, digits := input[0], input[1]
		if length != 2 || base < 3 || base > 16 || digits < 1 || digits > 10 { return -1 }
		mut limit := i64(1)
		for _ in 0 .. int(digits) { limit *= base }
		if limit > max_limit { return -1 }
		return search(base, digits)
	}
}
