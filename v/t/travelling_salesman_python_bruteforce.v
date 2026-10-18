module main

import math

const max_cities = 8
const coordinate_limit = 16.0

@[export: 'travelling_salesman_python_bruteforce']
pub fn travelling_salesman_python_bruteforce(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_len < 3 || input_len > 17 { return -1 }
		raw_count := input[0]
		if raw_count != raw_count || raw_count < 2.0 || raw_count > 8.0 || raw_count != math.floor(raw_count) { return -1 }
		city_count := int(raw_count)
		if input_len != 1 + 2 * city_count { return -1 }

		mut x := [max_cities]f64{}
		mut y := [max_cities]f64{}
		for city in 0 .. city_count {
			x[city] = input[1 + 2 * city]
			y[city] = input[2 + 2 * city]
			if x[city] != x[city] || y[city] != y[city] ||
				x[city] < -coordinate_limit || x[city] > coordinate_limit ||
				y[city] < -coordinate_limit || y[city] > coordinate_limit ||
				x[city] != math.floor(x[city]) || y[city] != math.floor(y[city]) { return -1 }
		}

		permutation_len := city_count - 1
		mut order := [max_cities - 1]int{}
		mut best_order := [max_cities - 1]int{}
		for i in 0 .. permutation_len { order[i] = i + 1 }
		mut best_distance := 1.0e300
		for {
			mut total := 0.0
			mut previous := 0
			for i in 0 .. permutation_len + 1 {
				next := if i == permutation_len { 0 } else { order[i] }
				dx := x[next] - x[previous]
				dy := y[next] - y[previous]
				total += math.sqrt(dx * dx + dy * dy)
				previous = next
			}
			if total < best_distance {
				best_distance = total
				for i in 0 .. permutation_len { best_order[i] = order[i] }
			}

			mut i := permutation_len
			for i > 1 && order[i - 2] >= order[i - 1] { i-- }
			if i <= 1 { break }
			pivot := i - 2
			mut j := permutation_len - 1
			for order[j] <= order[pivot] { j-- }
			order[pivot], order[j] = order[j], order[pivot]
			mut left := i - 1
			mut right := permutation_len - 1
			for left < right {
				order[left], order[right] = order[right], order[left]
				left++
				right--
			}
		}

		mut result := [11]f64{}
		path_len := city_count + 1
		result[0] = f64(path_len)
		result[1] = 0.0
		for i in 0 .. permutation_len { result[2 + i] = f64(best_order[i]) }
		result[path_len] = 0.0
		result[path_len + 1] = best_distance
		required := city_count + 3
		if output == nil || output_capacity < required { return -2 }
		for i in 0 .. required { output[i] = result[i] }
		return i64(required)
	}
}
