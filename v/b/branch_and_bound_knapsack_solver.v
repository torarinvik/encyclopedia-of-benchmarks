module branch_and_bound_knapsack_solver

struct SearchNode {
	level i32
	weight i32
	value i32
	mask i32
}

fn upper_bound(weights [8]i32, item_values [8]i32, count i32, capacity i32,
	level i32, weight i32, value i32) f64 {
	mut available := capacity - weight
	mut bound := f64(value)
	mut next := level + 1
	for available > 0 && next < count {
		if weights[next] <= available {
			bound += f64(item_values[next])
			available -= weights[next]
		} else {
			bound += f64(item_values[next]) / f64(weights[next]) * f64(available)
			available = 0
		}
		next++
	}
	return bound
}

// Breadth-first branch-and-bound for bounded 0/1 knapsack.
@[export: 'branch_and_bound_knapsack_solver']
pub fn branch_and_bound_knapsack_solver(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if length < 2 || length > 18 { return -1 }
		if input[0] < 0 || input[0] > 8 || input[1] < 0 || input[1] > 8000 { return -1 }
		count := i32(input[0])
		capacity := i32(input[1])
		if length != 2 + 2 * usize(count) { return -1 }

		mut weights := [8]i32{}
		mut item_values := [8]i32{}
		mut item_ids := [8]i32{}
		for index := i32(0); index < count; index++ {
			weight := input[2 + 2 * usize(index)]
			value := input[3 + 2 * usize(index)]
			if weight < 1 || weight > 1000 || value < 1 || value > 1000 { return -1 }
			mut position := index
			for position > 0 && value * i64(weights[position - 1]) > i64(item_values[position - 1]) * weight {
				weights[position] = weights[position - 1]
				item_values[position] = item_values[position - 1]
				item_ids[position] = item_ids[position - 1]
				position--
			}
			weights[position] = i32(weight)
			item_values[position] = i32(value)
			item_ids[position] = index
		}

		mut queue := [511]SearchNode{}
		mut head := usize(0)
		mut tail := usize(1)
		queue[0] = SearchNode{-1, 0, 0, 0}
		mut best_value := i32(0)
		mut best_mask := i32(0)
		for head < tail {
			parent := queue[head]
			head++
			if parent.level == count - 1 { continue }
			next := parent.level + 1
			left := SearchNode{next, parent.weight + weights[next], parent.value + item_values[next],
				parent.mask | (1 << u32(next))}
			right := SearchNode{next, parent.weight, parent.value, parent.mask}
			if left.weight <= capacity && left.value > best_value {
				best_value = left.value
				best_mask = left.mask
			}
			if upper_bound(weights, item_values, count, capacity, left.level, left.weight, left.value) > f64(best_value) && left.weight < capacity {
				queue[tail] = left
				tail++
			}
			if upper_bound(weights, item_values, count, capacity, right.level, right.weight, right.value) > f64(best_value) {
				queue[tail] = right
				tail++
			}
		}

		mut selected := [8]u8{}
		mut selected_count := usize(0)
		mut level := count - 1
		for level >= 0 {
			if best_mask & (1 << u32(level)) != 0 {
				selected[selected_count] = u8(item_ids[level])
				selected_count++
			}
			level--
		}
		if selected_count > output_capacity || (selected_count != 0 && isnil(output)) { return -2 }
		for index := usize(0); index < selected_count; index++ { output[index] = selected[index] }
		return i64(selected_count)
	}
}
