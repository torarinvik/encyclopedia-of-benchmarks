package problem74

MAX_START :: i64(1_000_000)
CACHE_SIZE :: 2_540_161
MAX_PATH_LENGTH :: 128
DIGIT_FACTORIALS :: [10]i64{1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880}

sum_digit_factorials :: proc(value: i64) -> i64 {
	remaining := value
	total: i64 = 0
	for remaining > 0 {
		total += DIGIT_FACTORIALS[int(remaining % 10)]
		remaining /= 10
	}
	if value == 0 { return 1 }
	return total
}

chain_length :: proc(start: i64, cache: [^]u8) -> i64 {
	path: [MAX_PATH_LENGTH]i64 = {}
	path_length := 0
	current := start
	result: i64 = 0
	for {
		encoded := cache[int(current)]
		if encoded != 0 {
			result = i64(encoded) - 1
			break
		}
		next_value := sum_digit_factorials(current)
		repeats := false
		for index := 0; index < path_length; index += 1 {
			if path[index] == next_value { repeats = true; break }
		}
		if repeats {
			cache[int(current)] = 1
			result = 0
			break
		}
		path[path_length] = current
		path_length += 1
		current = next_value
	}
	for path_length > 0 {
		path_length -= 1
		current = path[path_length]
		result += 1
		cache[int(current)] = u8(result + 1)
	}
	return i64(cache[int(start)]) - 1
}

@(export)
problem74 :: proc "c" (num_terms, max_start: i64) -> i64 {
	if max_start > MAX_START do return -1
	if max_start <= 1 do return 0
	cache: [CACHE_SIZE]u8 = {}
	cache[145] = 1
	cache[169] = 4
	cache[36301] = 4
	cache[1454] = 4
	cache[871] = 3
	cache[45361] = 3
	cache[872] = 3
	count: i64 = 0
	for start: i64 = 1; start < max_start; start += 1 {
		if chain_length(start, &cache[0]) == num_terms { count += 1 }
	}
	return count
}
