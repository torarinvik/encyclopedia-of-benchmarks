const invalid_result = -1.0e300
const max_parseable_input_length = usize(67)
const max_cities = 8

fn next_permutation(mut cities [7]int, length int) bool {
	if length < 2 { return false }
	mut pivot := length - 1
	for pivot > 0 && cities[pivot - 1] >= cities[pivot] { pivot-- }
	if pivot == 0 { return false }
	pivot_index := pivot - 1
	mut successor := length - 1
	for cities[successor] <= cities[pivot_index] { successor-- }
	cities[pivot_index], cities[successor] = cities[successor], cities[pivot_index]
	mut left := pivot
	mut right := length - 1
	for left < right {
		cities[left], cities[right] = cities[right], cities[left]
		left++
		right--
	}
	return true
}

@[export: 'traveling_salesman_solver_brute_force']
pub fn traveling_salesman_solver_brute_force(input &i64, length usize) f64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_input_length { return invalid_result }
		selector_value, city_count_value := input[0], input[1]
		if city_count_value < 2 || city_count_value > max_cities { return invalid_result }
		city_count := int(city_count_value)
		if selector_value < 0 || selector_value > i64(city_count + 1) ||
			length != usize(2 + city_count * city_count) { return invalid_result }

		mut distances := [64]i64{}
		for index in 0 .. city_count * city_count {
			value := input[2 + index]
			if value < 0 || value > 1000 { return invalid_result }
			distances[index] = value
		}

		mut cities := [7]int{}
		for index in 0 .. city_count - 1 { cities[index] = index + 1 }
		mut best_distance := i64(9_223_372_036_854_775_807)
		mut best_route := [9]int{}
		for {
			mut route := [9]int{}
			route[0] = 0
			for index in 0 .. city_count - 1 { route[index + 1] = cities[index] }
			route[city_count] = 0

			mut distance := i64(0)
			for edge_index in 0 .. city_count {
				from := route[edge_index]
				to := route[edge_index + 1]
				distance += distances[from * city_count + to]
			}
			if distance < best_distance {
				best_distance = distance
				best_route = route
			}
			if !next_permutation(mut cities, city_count - 1) { break }
		}

		if selector_value == 0 { return f64(best_distance) }
		return f64(best_route[int(selector_value - 1)])
	}
}
