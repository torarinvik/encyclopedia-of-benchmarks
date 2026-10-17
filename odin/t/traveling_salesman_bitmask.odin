package traveling_salesman_bitmask

import "core:c"

MAX_CITIES :: 10
MAX_MASKS :: 1024
MAX_STATES :: MAX_CITIES * MAX_MASKS
MAX_INPUT_VALUES :: 102

solve :: proc "contextless" (position, mask, city_count: int,
                              distances, memo: [^]i64,
                              seen: [^]bool) -> i64 {
	all_visited := (1 << city_count) - 1
	if mask == all_visited do return distances[position * city_count]
	state := position * MAX_MASKS + mask
	if seen[state] do return memo[state]

	seen[state] = true
	best := i64(10001)
	for city := 0; city < city_count; city += 1 {
		bit := 1 << city
		if (mask & bit) == 0 {
			cost := distances[position * city_count + city] +
				solve(city, mask | bit, city_count, distances, memo, seen)
			if cost < best do best = cost
		}
	}
	memo[state] = best
	return best
}

@(export)
traveling_salesman_bitmask :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	city_count_value := input[0]
	if city_count_value < 2 || city_count_value > MAX_CITIES do return -1
	city_count := int(city_count_value)
	if length != c.size_t(1 + city_count * city_count) do return -1

	var distances: [MAX_CITIES * MAX_CITIES]i64
	for index := 0; index < city_count * city_count; index += 1 {
		distance := input[1 + index]
		if distance < 0 || distance > 1000 do return -1
		if index / city_count == index % city_count && distance != 0 do return -1
		distances[index] = distance
	}

	var memo: [MAX_STATES]i64
	var seen: [MAX_STATES]bool
	return solve(0, 1, city_count, &distances[0], &memo[0], &seen[0])
}
