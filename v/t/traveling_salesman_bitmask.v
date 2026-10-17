const max_cities = 10
const max_masks = 1024
const max_states = max_cities * max_masks
const max_input_values = usize(102)
const max_distance = i64(1000)

fn solve(position int, mask int, city_count int, distances []i64, mut memo []i64, mut seen []bool) i64 {
	all_visited := (1 << city_count) - 1
	if mask == all_visited { return distances[position * city_count] }
	state := position * max_masks + mask
	if seen[state] { return memo[state] }

	seen[state] = true
	mut best := i64(10001)
	for city in 0 .. city_count {
		bit := 1 << city
		if (mask & bit) == 0 {
			cost := distances[position * city_count + city] + solve(city, mask | bit, city_count, distances, mut memo, mut seen)
			if cost < best { best = cost }
		}
	}
	memo[state] = best
	return best
}

@[export: 'traveling_salesman_bitmask']
pub fn traveling_salesman_bitmask(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values { return -1 }
	unsafe {
		city_count_value := input[0]
		if city_count_value < 2 || city_count_value > i64(max_cities) { return -1 }
		city_count := int(city_count_value)
		if length != usize(1 + city_count * city_count) { return -1 }

		mut distances := []i64{len: max_cities * max_cities}
		for index in 0 .. city_count * city_count {
			distance := input[1 + index]
			if distance < 0 || distance > max_distance { return -1 }
			if index / city_count == index % city_count && distance != 0 { return -1 }
			distances[index] = distance
		}

		mut memo := []i64{len: max_states}
		mut seen := []bool{len: max_states}
		return solve(0, 1, city_count, distances, mut memo, mut seen)
	}
}
