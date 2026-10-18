package traveling_salesman_solver_nearest_neighbor

import "core:c"

MAX_CITIES :: 8
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(68)
MAX_EDGE_COST :: i64(1000)

@(export)
traveling_salesman_solver_nearest_neighbor :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1.0e300
	selector := input[0]
	city_count_value := input[1]
	start_value := input[2]
	if city_count_value < 1 || city_count_value > MAX_CITIES do return -1.0e300
	if selector < 0 || selector > city_count_value + 1 do return -1.0e300
	if start_value < 0 || start_value >= city_count_value do return -1.0e300
	city_count := int(city_count_value)
	start := int(start_value)
	if length != c.size_t(3 + city_count * city_count) do return -1.0e300

	var distances: [64]i64
	for index := 0; index < city_count * city_count; index += 1 {
		cost := input[index + 3]
		if cost < 0 || cost > MAX_EDGE_COST do return -1.0e300
		distances[index] = cost
	}

	var visited: [8]bool
	var route: [9]int
	route[0] = start
	visited[start] = true
	current := start
	total_distance := i64(0)

	for step := 1; step < city_count; step += 1 {
		minimum_distance := MAX_EDGE_COST + 1
		next_city := -1
		for city := 0; city < city_count; city += 1 {
			if !visited[city] {
				cost := distances[current * city_count + city]
				if cost < minimum_distance {
					minimum_distance = cost
					next_city = city
				}
			}
		}
		if next_city < 0 do return -1.0e300
		route[step] = next_city
		visited[next_city] = true
		total_distance += minimum_distance
		current = next_city
	}

	total_distance += distances[current * city_count + start]
	route[city_count] = start
	if selector == 0 do return f64(total_distance)
	return f64(route[int(selector - 1)])
}
