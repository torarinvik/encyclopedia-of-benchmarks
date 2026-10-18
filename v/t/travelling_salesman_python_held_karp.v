import math

const max_cities = 8
const max_masks = 256
const max_input_values = 17
const max_output_values = 11
const inf_cost = 1e300

@[export: 'travelling_salesman_dynamic_programming']
pub fn travelling_salesman_dynamic_programming(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > max_input_values { return -1 }
		n_value := input[0]
		if !n_value.is_finite() || n_value < 2.0 || n_value > f64(max_cities) || n_value.trunc() != n_value { return -1 }
		n := int(n_value)
		if input_length != usize(1 + 2 * n) { return -1 }

		mut x := [max_cities]f64{}
		mut y := [max_cities]f64{}
		for city in 0 .. n {
			cx := input[1 + 2 * city]
			cy := input[2 + 2 * city]
			if !cx.is_finite() || !cy.is_finite() || cx < -16.0 || cx > 16.0 || cy < -16.0 || cy > 16.0 ||
				cx.trunc() != cx || cy.trunc() != cy { return -1 }
			x[city] = cx
			y[city] = cy
		}

		mut distances := [max_cities * max_cities]f64{}
		for from in 0 .. n {
			for to in 0 .. n {
				dx := x[to] - x[from]
				dy := y[to] - y[from]
				distances[from * max_cities + to] = math.sqrt(dx * dx + dy * dy)
			}
		}

		mut dp := [max_masks * max_cities]f64{}
		for state in 0 .. max_masks * max_cities { dp[state] = inf_cost }
		dp[max_cities] = 0.0
		mask_count := 1 << n
		for mask in 0 .. mask_count {
			for u in 0 .. n {
				if (mask & (1 << u)) == 0 { continue }
				prefix := dp[mask * max_cities + u]
				for v in 0 .. n {
					bit := 1 << v
					if (mask & bit) != 0 { continue }
					next_mask := mask | bit
					candidate := prefix + distances[u * max_cities + v]
					if candidate < dp[next_mask * max_cities + v] { dp[next_mask * max_cities + v] = candidate }
				}
			}
		}

		final_mask := mask_count - 1
		mut minimum := inf_cost
		mut end_node := n
		for u in 1 .. n {
			candidate := dp[final_mask * max_cities + u] + distances[u * max_cities]
			if minimum > candidate { minimum = candidate; end_node = u }
		}
		if end_node == n { return -1 }

		mut reverse_path := [max_cities + 1]int{}
		mut path_length := 0
		mut mask := final_mask
		for end_node != 0 {
			reverse_path[path_length] = end_node
			path_length++
			previous_mask := mask ^ (1 << end_node)
			mut found := false
			for u in 0 .. n {
				if (mask & (1 << u)) == 0 { continue }
				if dp[mask * max_cities + end_node] == dp[previous_mask * max_cities + u] + distances[u * max_cities + end_node] {
					mask = previous_mask
					end_node = u
					found = true
					break
				}
			}
			if !found || path_length > max_cities { return -1 }
		}
		reverse_path[path_length] = 0
		path_length++
		mut left := 0
		mut right := path_length - 1
		for left < right {
			reverse_path[left], reverse_path[right] = reverse_path[right], reverse_path[left]
			left++
			right--
		}
		reverse_path[path_length] = 0
		path_length++

		mut staged := [max_output_values]f64{}
		staged[0] = f64(path_length)
		for index in 0 .. path_length { staged[index + 1] = f64(reverse_path[index]) }
		staged[path_length + 1] = minimum
		output_size := path_length + 2
		if output == nil || capacity < output_size { return -2 }
		for index in 0 .. output_size { output[index] = staged[index] }
		return i64(output_size)
	}
}
