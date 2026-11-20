package left_truncatable_prime_search

import "core:c"

MAX_LIMIT :: 100_000
MAX_QUEUE :: 70_000

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	if value % 2 == 0 do return value == 2
	divisor := i64(3)
	for divisor * divisor <= value {
		if value % divisor == 0 do return false
		divisor += 2
	}
	return true
}

search :: proc(base, digits: i64) -> i64 {
	queue: [MAX_QUEUE]i64 = {}
	end := 0
	for value := i64(2); value < base; value += 1 {
		if is_prime(value) {
			queue[end] = value
			end += 1
		}
	}
	best := queue[end - 1]
	level_start, level_end := 0, end
	place := base
	for width := i64(1); width < digits && level_start < level_end; width += 1 {
		for index := level_start; index < level_end; index += 1 {
			suffix := queue[index]
			for leading := i64(1); leading < base; leading += 1 {
				candidate := leading * place + suffix
				if is_prime(candidate) {
					if end >= MAX_QUEUE do return -1
					queue[end] = candidate
					end += 1
					if candidate > best do best = candidate
				}
			}
		}
		level_start = level_end
		level_end = end
		place *= base
	}
	return best
}

@(export)
left_truncatable_prime_search :: proc(input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 3 do return -1
	base, digits := input[0], input[1]
	if length != 2 || base < 3 || base > 16 || digits < 1 || digits > 10 do return -1
	limit := i64(1)
	for index := i64(0); index < digits; index += 1 do limit *= base
	if limit > MAX_LIMIT do return -1
	return search(base, digits)
}
