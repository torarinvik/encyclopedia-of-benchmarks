const invalid_result = -1.0e300
const max_parseable_input_length = usize(68)
const max_cities = 8

@[export: 'traveling_salesman_solver_nearest_neighbor']
pub fn traveling_salesman_solver_nearest_neighbor(input &i64, length usize) f64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_input_length { return invalid_result }
		selector_value, city_count_value, start_value := input[0], input[1], input[2]
		if city_count_value < 1 || city_count_value > max_cities { return invalid_result }
		city_count := int(city_count_value)
		if selector_value < 0 || selector_value > i64(city_count + 1) ||
			start_value < 0 || start_value >= city_count_value ||
			length != usize(3 + city_count * city_count) { return invalid_result }

		mut distances := [64]i64{}
		for index in 0 .. city_count * city_count {
			value := input[3 + index]
			if value < 0 || value > 1000 { return invalid_result }
			distances[index] = value
		}

		start := int(start_value)
		mut route := [9]int{}
		mut visited := [8]bool{}
		route[0] = start
		visited[start] = true
		mut current := start
		mut total_distance := i64(0)
		for step in 0 .. city_count - 1 {
			mut next_city := -1
			mut minimum_distance := i64(1001)
			for city in 0 .. city_count {
				if !visited[city] {
					distance := distances[current * city_count + city]
					if distance < minimum_distance {
						minimum_distance = distance
						next_city = city
					}
				}
			}
			if next_city < 0 { return invalid_result }
			route[step + 1] = next_city
			visited[next_city] = true
			total_distance += minimum_distance
			current = next_city
		}
		route[city_count] = start
		total_distance += distances[current * city_count + start]

		if selector_value == 0 { return f64(total_distance) }
		return f64(route[int(selector_value - 1)])
	}
}
