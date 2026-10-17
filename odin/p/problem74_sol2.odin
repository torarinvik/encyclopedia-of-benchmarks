package problem74_sol2

MAX_CHAIN_LENGTH :: 60
MAX_NUMBER_LIMIT :: 1_000_000
PATH_CAPACITY :: MAX_CHAIN_LENGTH + 1
DIGIT_FACTORIALS :: [10]i64{1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880}

digit_factorial_sum :: proc(value: i64) -> i64 {
	remaining := value
	total: i64 = 0
	for remaining > 0 {
		total += DIGIT_FACTORIALS[int(remaining % 10)]
		remaining /= 10
	}
	if value == 0 { return 1 }
	return total
}

cache_contains :: proc(value, number_limit: i64, cache: []u32) -> bool {
	return value >= 1 && value < number_limit && cache[int(value)] != 0
}

path_contains :: proc(path: []i64, value: i64) -> bool {
	for term in path {
		if term == value { return true }
	}
	return false
}

@(export)
problem74_sol2 :: proc "c" (chain_length, number_limit: i64) -> i64 {
	if chain_length < 1 || chain_length > MAX_CHAIN_LENGTH ||
		number_limit < 1 || number_limit > MAX_NUMBER_LIMIT do return -1
	if number_limit == 1 do return 0

	cache := make([]u32, int(number_limit))
	defer delete(cache)
	chains_counter: i64 = 0
	for start: i64 = 1; start < number_limit; start += 1 {
		path: [PATH_CAPACITY]i64 = {}
		path_length := 0
		chain_set_length: i64 = 0
		chain_element := start
		for !cache_contains(chain_element, number_limit, cache) &&
			!path_contains(path[:path_length], chain_element) && chain_set_length <= chain_length {
			path[path_length] = chain_element
			path_length += 1
			chain_set_length += 1
			chain_element = digit_factorial_sum(chain_element)
		}
		if cache_contains(chain_element, number_limit, cache) {
			chain_set_length += i64(cache[int(chain_element)])
		}
		cache[int(start)] = u32(chain_set_length)
		if chain_set_length == chain_length { chains_counter += 1 }
	}
	return chains_counter
}
