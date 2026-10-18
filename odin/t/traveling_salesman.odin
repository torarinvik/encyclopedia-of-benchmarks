package traveling_salesman

import "core:c"

MAX_CITIES :: 8
MAX_INPUT_LENGTH :: c.size_t(66)
JAVA_INT_MIN :: i64(-2_147_483_648)
JAVA_INT_MAX :: i64(2_147_483_647)
MAX_EDGE_COST :: i64(1_000)

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
traveling_salesman :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	city_count_value := input[0]
	if city_count_value < 0 || city_count_value > MAX_CITIES do return -1
	city_count := int(city_count_value)
	if length != c.size_t(1 + city_count * city_count) do return -1

	var distances: [64]i64
	for index := 0; index < city_count * city_count; index += 1 {
		distance := input[index + 1]
		if distance < JAVA_INT_MIN || distance > JAVA_INT_MAX do return -1
		if city_count > 1 && index / city_count != index % city_count &&
			distance != JAVA_INT_MAX && (distance < 0 || distance > MAX_EDGE_COST) do return -1
		distances[index] = distance
	}
	if city_count <= 1 do return 0

	permutation_length := city_count - 1
	var permutation: [7]int
	for index := 0; index < permutation_length; index += 1 {
		permutation[index] = index + 1
	}

	best := JAVA_INT_MAX
	for {
		route_cost := i64(0)
		previous := 0
		route_valid := true
		for index := 0; index < permutation_length; index += 1 {
			city := permutation[index]
			edge := distances[previous * city_count + city]
			if edge == JAVA_INT_MAX {
				route_valid = false
				break
			}
			route_cost += edge
			previous = city
		}

		if route_valid {
			return_edge := distances[previous * city_count]
			if return_edge != JAVA_INT_MAX {
				route_cost += return_edge
				if route_cost < best do best = route_cost
			}
		}
		if !next_permutation(&permutation[0], permutation_length) do break
	}
	return best
}
