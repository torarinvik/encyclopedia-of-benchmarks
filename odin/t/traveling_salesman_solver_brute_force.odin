package traveling_salesman_solver_brute_force

import "core:c"

MAX_CITIES :: 8
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(67)
MAX_EDGE_COST :: i64(1000)

next_permutation :: proc "contextless" (values: [^]int, length: int) -> bool {
	if length < 2 do return false
	pivot := length - 1
	for pivot > 0 && values[pivot - 1] >= values[pivot] {
		pivot -= 1
	}
	if pivot == 0 do return false
	pivot -= 1

	successor := length - 1
	for values[successor] <= values[pivot] {
		successor -= 1
	}
	temporary := values[pivot]
	values[pivot] = values[successor]
	values[successor] = temporary

	left := pivot + 1
	right := length - 1
	for left < right {
		temporary = values[left]
		values[left] = values[right]
		values[right] = temporary
		left += 1
		right -= 1
	}
	return true
}

@(export)
traveling_salesman_solver_brute_force :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1.0e300
	selector := input[0]
	city_count_value := input[1]
	if city_count_value < 2 || city_count_value > MAX_CITIES do return -1.0e300
	if selector < 0 || selector > city_count_value + 1 do return -1.0e300
	city_count := int(city_count_value)
	if length != c.size_t(2 + city_count * city_count) do return -1.0e300

	var distances: [64]i64
	for index := 0; index < city_count * city_count; index += 1 {
		cost := input[index + 2]
		if cost < 0 || cost > MAX_EDGE_COST do return -1.0e300
		distances[index] = cost
	}

	permutation_length := city_count - 1
	var permutation: [7]int
	for index := 0; index < permutation_length; index += 1 {
		permutation[index] = index + 1
	}

	best_distance := i64(9223372036854775807)
	var best_route: [9]int
	for {
		var route: [9]int
		route[0] = 0
		for index := 0; index < permutation_length; index += 1 {
			route[index + 1] = permutation[index]
		}
		route[city_count] = 0

		distance := i64(0)
		for index := 0; index < city_count; index += 1 {
			distance += distances[route[index] * city_count + route[index + 1]]
		}
		if distance < best_distance {
			best_distance = distance
			for index := 0; index <= city_count; index += 1 {
				best_route[index] = route[index]
			}
		}

		if !next_permutation(&permutation[0], permutation_length) do break
	}
	if selector == 0 do return f64(best_distance)
	return f64(best_route[int(selector - 1)])
}
