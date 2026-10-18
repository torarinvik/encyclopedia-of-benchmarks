const max_parseable_input_length = usize(66)
const java_int_min = i64(-2_147_483_648)
const java_int_max = i64(2_147_483_647)
const max_finite_edge_cost = i64(1000)

fn next_permutation(mut cities []int) bool {
	if cities.len < 2 { return false }
	mut pivot := cities.len - 1
	for pivot > 0 && cities[pivot - 1] >= cities[pivot] { pivot-- }
	if pivot == 0 { return false }
	pivot_index := pivot - 1
	mut successor := cities.len - 1
	for cities[successor] <= cities[pivot_index] { successor-- }
	cities[pivot_index], cities[successor] = cities[successor], cities[pivot_index]
	mut left := pivot
	mut right := cities.len - 1
	for left < right {
		cities[left], cities[right] = cities[right], cities[left]
		left++
		right--
	}
	return true
}

@[export: 'traveling_salesman']
pub fn traveling_salesman(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input_length { return -1 }
		city_count_value := input[0]
		if city_count_value < 0 || city_count_value > 8 { return -1 }
		city_count := int(city_count_value)
		if length != usize(1 + city_count * city_count) { return -1 }

		mut distances := [64]i64{}
		for index in 0 .. city_count * city_count {
			value := input[1 + index]
			if value < java_int_min || value > java_int_max { return -1 }
			distances[index] = value
		}
		if city_count <= 1 { return 0 }

		for row in 0 .. city_count {
			for column in 0 .. city_count {
				if row == column { continue }
				value := distances[row * city_count + column]
				if value != java_int_max && (value < 0 || value > max_finite_edge_cost) { return -1 }
			}
		}

		mut cities := [7]int{}
		for index in 0 .. city_count - 1 { cities[index] = index + 1 }
		mut best := java_int_max
		for {
			mut previous := 0
			mut cost := i64(0)
			mut valid := true
			for city in cities[..city_count - 1] {
				edge := distances[previous * city_count + city]
				if edge == java_int_max { valid = false; break }
				cost += edge
				previous = city
			}
			if valid {
				return_edge := distances[previous * city_count]
				if return_edge == java_int_max { valid = false }
				else { cost += return_edge }
			}
			if valid && cost < best { best = cost }
			if !next_permutation(mut cities[..city_count - 1]) { break }
		}
		return best
	}
}
