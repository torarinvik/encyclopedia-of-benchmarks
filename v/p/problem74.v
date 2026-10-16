module problem74

const max_start = i64(1_000_000)
const cache_size = 2_540_161
const max_path_length = 128
const digit_factorials = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

fn sum_digit_factorials(value i64) i64 {
	mut remaining := value
	mut total := i64(0)
	for remaining > 0 {
		total += i64(digit_factorials[int(remaining % 10)])
		remaining /= 10
	}
	if value == 0 {
		return 1
	}
	return total
}

@[export: 'problem74']
pub fn problem74(num_terms i64, upper_start i64) i64 {
	if upper_start > max_start {
		return -1
	}
	if upper_start <= 1 {
		return 0
	}
	mut cache := [cache_size]u8{}
	cache[145] = 1
	cache[169] = 4
	cache[36301] = 4
	cache[1454] = 4
	cache[871] = 3
	cache[45361] = 3
	cache[872] = 3
	mut count := i64(0)
	mut start := i64(1)
	for start < upper_start {
		mut path := [max_path_length]i64{}
		mut path_length := 0
		mut current := start
		mut chain_result := i64(0)
		for {
			encoded := cache[int(current)]
			if encoded != 0 {
				chain_result = i64(encoded) - 1
				break
			}
			next_value := sum_digit_factorials(current)
			mut repeats := false
			for index in 0 .. path_length {
				if path[index] == next_value {
					repeats = true
					break
				}
			}
			if repeats {
				cache[int(current)] = 1
				chain_result = 0
				break
			}
			path[path_length] = current
			path_length++
			current = next_value
		}
		for path_length > 0 {
			path_length--
			current = path[path_length]
			chain_result++
			cache[int(current)] = u8(chain_result + 1)
		}
		if i64(cache[int(start)]) - 1 == num_terms {
			count++
		}
		start++
	}
	return count
}
