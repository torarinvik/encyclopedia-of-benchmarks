package branch_and_bound_knapsack_solver

import "core:c"

Search_Node :: struct {
	level: i32,
	weight: i32,
	value: i32,
	mask: i32,
}

upper_bound :: proc "c" (weights, item_values: [8]i32, count, capacity, level, weight, value: i32) -> f64 {
	available := capacity - weight
	bound := f64(value)
	next := level + 1
	for available > 0 && next < count {
		if weights[next] <= available {
			bound += f64(item_values[next])
			available -= weights[next]
		} else {
			bound += f64(item_values[next]) / f64(weights[next]) * f64(available)
			available = 0
		}
		next += 1
	}
	return bound
}

// Breadth-first branch-and-bound for bounded 0/1 knapsack.
@(export)
branch_and_bound_knapsack_solver :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 18 do return -1
	if input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 8000 do return -1
	count := i32(input[0])
	capacity := i32(input[1])
	if length != 2 + 2 * c.size_t(count) do return -1

	weights: [8]i32
	item_values: [8]i32
	item_ids: [8]i32
	for index: i32 = 0; index < count; index += 1 {
		weight := input[2 + 2 * c.size_t(index)]
		value := input[3 + 2 * c.size_t(index)]
		if weight < 1 || weight > 1000 || value < 1 || value > 1000 do return -1
		position := index
		for position > 0 && value * i64(weights[position - 1]) > i64(item_values[position - 1]) * weight {
			weights[position] = weights[position - 1]
			item_values[position] = item_values[position - 1]
			item_ids[position] = item_ids[position - 1]
			position -= 1
		}
		weights[position] = i32(weight)
		item_values[position] = i32(value)
		item_ids[position] = index
	}

	queue: [511]Search_Node
	head := c.size_t(0)
	tail := c.size_t(1)
	queue[0] = Search_Node{-1, 0, 0, 0}
	best_value := i32(0)
	best_mask := i32(0)
	for head < tail {
		parent := queue[head]
		head += 1
		if parent.level == count - 1 do continue
		next := parent.level + 1
		left := Search_Node{next, parent.weight + weights[next], parent.value + item_values[next],
			parent.mask | (1 << u32(next))}
		right := Search_Node{next, parent.weight, parent.value, parent.mask}
		if left.weight <= capacity && left.value > best_value {
			best_value = left.value
			best_mask = left.mask
		}
		if upper_bound(weights, item_values, count, capacity, left.level, left.weight, left.value) > f64(best_value) && left.weight < capacity {
			queue[tail] = left
			tail += 1
		}
		if upper_bound(weights, item_values, count, capacity, right.level, right.weight, right.value) > f64(best_value) {
			queue[tail] = right
			tail += 1
		}
	}

	selected: [8]u8
	selected_count := c.size_t(0)
	for level := count - 1; level >= 0; level -= 1 {
		if (best_mask & (1 << u32(level))) != 0 {
			selected[selected_count] = u8(item_ids[level])
			selected_count += 1
		}
	}
	if selected_count > output_capacity || (selected_count != 0 && output == nil) do return -2
	for index: c.size_t = 0; index < selected_count; index += 1 { output[index] = selected[index] }
	return i64(selected_count)
}
