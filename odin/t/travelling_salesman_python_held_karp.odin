package travelling_salesman_python_held_karp

import "core:c"
import "core:math"

MAX_CITIES :: 8
MAX_INPUT_VALUES :: 17
MAX_OUTPUT_VALUES :: 11
MAX_MASKS :: 256
INF_COST :: 1e300

@(export)
travelling_salesman_dynamic_programming :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 5 || input_length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	if !math.is_finite(n_value) || n_value < 2.0 || n_value > f64(MAX_CITIES) || math.trunc(n_value) != n_value do return -1
	n := int(n_value)
	if int(input_length) != 1 + 2*n do return -1

	var x, y: [MAX_CITIES]f64
	for city := 0; city < n; city += 1 {
		cx, cy := input[1+2*city], input[2+2*city]
		if !math.is_finite(cx) || !math.is_finite(cy) || cx < -16.0 || cx > 16.0 || cy < -16.0 || cy > 16.0 ||
			math.trunc(cx) != cx || math.trunc(cy) != cy do return -1
		x[city], y[city] = cx, cy
	}

	var distances: [MAX_CITIES * MAX_CITIES]f64
	for from := 0; from < n; from += 1 {
		for to := 0; to < n; to += 1 {
			dx, dy := x[to]-x[from], y[to]-y[from]
			distances[from*MAX_CITIES+to] = math.sqrt(dx*dx+dy*dy)
		}
	}

	var dp: [MAX_MASKS * MAX_CITIES]f64
	for state := 0; state < MAX_MASKS * MAX_CITIES; state += 1 { dp[state] = INF_COST }
	dp[MAX_CITIES] = 0.0
	mask_count := 1 << n
	for mask := 0; mask < mask_count; mask += 1 {
		for u := 0; u < n; u += 1 {
			if (mask & (1 << u)) == 0 do continue
			prefix := dp[mask*MAX_CITIES+u]
			for v := 0; v < n; v += 1 {
				bit := 1 << v
				if (mask & bit) != 0 do continue
				next_mask := mask | bit
				candidate := prefix + distances[u*MAX_CITIES+v]
				if candidate < dp[next_mask*MAX_CITIES+v] do dp[next_mask*MAX_CITIES+v] = candidate
			}
		}
	}

	final_mask := mask_count - 1
	minimum := INF_COST
	end_node := n
	for u := 1; u < n; u += 1 {
		candidate := dp[final_mask*MAX_CITIES+u] + distances[u*MAX_CITIES]
		if minimum > candidate { minimum = candidate; end_node = u }
	}
	if end_node == n do return -1

	var reverse_path: [MAX_CITIES + 1]int
	path_length := 0
	mask := final_mask
	for end_node != 0 {
		reverse_path[path_length] = end_node
		path_length += 1
		previous_mask := mask ^ (1 << end_node)
		found := false
		for u := 0; u < n; u += 1 {
			if (mask & (1 << u)) == 0 do continue
			if dp[mask*MAX_CITIES+end_node] == dp[previous_mask*MAX_CITIES+u] + distances[u*MAX_CITIES+end_node] {
				mask = previous_mask
				end_node = u
				found = true
				break
			}
		}
		if !found || path_length > MAX_CITIES do return -1
	}
	reverse_path[path_length] = 0
	path_length += 1
	left := 0
	right := path_length - 1
	for left < right {
		reverse_path[left], reverse_path[right] = reverse_path[right], reverse_path[left]
		left += 1
		right -= 1
	}
	reverse_path[path_length] = 0
	path_length += 1

	var staged: [MAX_OUTPUT_VALUES]f64
	staged[0] = f64(path_length)
	for index := 0; index < path_length; index += 1 { staged[index+1] = f64(reverse_path[index]) }
	staged[path_length+1] = minimum
	output_size := path_length + 2
	if output == nil || capacity < c.size_t(output_size) do return -2
	for index := 0; index < output_size; index += 1 { output[index] = staged[index] }
	return i64(output_size)
}
