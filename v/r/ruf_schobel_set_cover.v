module ruf_schobel_set_cover

const max_rows = 6
const max_columns = 8
const max_input = 17
const max_stack = 32

fn store_i64_le(mut output []u8, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { output[byte] = u8((bits >> (8 * byte)) & 255) }
}

fn interval_cover(left []int, right []int, count int, weights []i64, columns int,
	mut out_cost i64, mut out_mask i64) bool {
	if count == 0 { out_cost = 0; out_mask = 0; return true }
	mut minimum_right := right[0]
	mut maximum_left := left[0]
	for i in 1 .. count {
		if right[i] < minimum_right { minimum_right = right[i] }
		if left[i] > maximum_left { maximum_left = left[i] }
	}
	mut costs := []i64{len: max_columns, init: 1000000}
	mut masks := []i64{len: max_columns}
	for point in 0 .. columns {
		if point <= minimum_right { costs[point] = weights[point]; masks[point] = i64(1) << point }
		for previous in 0 .. point {
			if costs[previous] == 1000000 { continue }
			mut blocked := false
			for i in 0 .. count {
				if previous < left[i] && right[i] < point { blocked = true; break }
			}
			if blocked { continue }
			candidate_cost := costs[previous] + weights[point]
			candidate_mask := masks[previous] | (i64(1) << point)
			if candidate_cost < costs[point] || (candidate_cost == costs[point] && candidate_mask < masks[point]) {
				costs[point] = candidate_cost
				masks[point] = candidate_mask
			}
		}
	}
	out_cost = 1000000
	out_mask = 0
	for point in maximum_left .. columns {
		if costs[point] < out_cost ||
			(costs[point] == out_cost && costs[point] != 1000000 && masks[point] < out_mask) {
			out_cost = costs[point]
			out_mask = masks[point]
		}
	}
	return out_cost != 1000000
}

@[export: 'ruf_schobel_set_cover']
pub fn ruf_schobel_set_cover(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		rows_raw := input[0]
		columns_raw := input[1]
		if rows_raw < 1 || rows_raw > max_rows || columns_raw < 1 || columns_raw > max_columns ||
			length != usize(2 + rows_raw + columns_raw) { return -1 }
		rows := int(rows_raw)
		columns := int(columns_raw)
		mut weights := []i64{len: max_columns}
		for column in 0 .. columns {
			weight := input[2 + column]
			if weight < 1 || weight > 20 { return -1 }
			weights[column] = weight
		}
		allowed := (u64(1) << columns) - 1
		mut row_masks := []u64{len: max_rows}
		mut block_left := [][]int{len: max_rows}
		mut block_right := [][]int{len: max_rows}
		for row in 0 .. max_rows {
			block_left[row] = []int{len: max_columns}
			block_right[row] = []int{len: max_columns}
		}
		mut block_count := []int{len: max_rows}
		for row in 0 .. rows {
			raw := input[2 + columns + row]
			if raw < 0 || (u64(raw) & ~allowed) != 0 { return -1 }
			row_masks[row] = u64(raw)
			mut column := 0
			for column < columns {
				if (row_masks[row] & (u64(1) << column)) == 0 { column++; continue }
				block := block_count[row]
				block_left[row][block] = column
				for column + 1 < columns && (row_masks[row] & (u64(1) << (column + 1))) != 0 { column++ }
				block_right[row][block] = column
				block_count[row]++
				column++
			}
		}
		for row in 0 .. rows {
			if row_masks[row] == 0 {
				if output == nil || capacity < 8 { return -2 }
				mut bytes := []u8{len: 8, init: 255}
				for byte in 0 .. 8 { output[byte] = bytes[byte] }
				return 8
			}
		}

		mut best_cost := i64(1000000)
		mut stack := [][]int{len: max_stack}
		for i in 0 .. max_stack { stack[i] = []int{len: max_rows, init: -1} }
		mut stack_size := 1
		for stack_size > 0 {
			stack_size--
			fixed := stack[stack_size].clone()
			mut left := []int{len: max_rows}
			mut right := []int{len: max_rows}
			mut count := 0
			for row in 0 .. rows {
				if block_count[row] == 1 || fixed[row] >= 0 {
					block := if block_count[row] == 1 { 0 } else { fixed[row] }
					left[count] = block_left[row][block]
					right[count] = block_right[row][block]
					count++
				}
			}
			mut lower_cost := i64(0)
			mut lower_mask := i64(0)
			if !interval_cover(left, right, count, weights, columns, mut lower_cost, mut lower_mask) { continue }
			mut extra_left := []int{len: max_rows}
			mut extra_right := []int{len: max_rows}
			mut extra_count := 0
			for row in 0 .. rows {
				if (row_masks[row] & u64(lower_mask)) != 0 { continue }
				mut chosen := 0
				mut chosen_cost := 1000000
				for block in 0 .. block_count[row] {
					mut cheapest := 1000000
					for column in block_left[row][block] .. block_right[row][block] + 1 {
						if int(weights[column]) < cheapest { cheapest = int(weights[column]) }
					}
					if cheapest < chosen_cost { chosen = block; chosen_cost = cheapest }
				}
				extra_left[extra_count] = block_left[row][chosen]
				extra_right[extra_count] = block_right[row][chosen]
				extra_count++
			}
			mut extra_cost := i64(0)
			mut extra_mask := i64(0)
			if !interval_cover(extra_left, extra_right, extra_count, weights, columns, mut extra_cost, mut extra_mask) { continue }
			candidate_mask := lower_mask | extra_mask
			mut candidate_cost := i64(0)
			for column in 0 .. columns {
				if (candidate_mask & (i64(1) << column)) != 0 { candidate_cost += weights[column] }
			}
			if candidate_cost < best_cost { best_cost = candidate_cost }
			if best_cost <= lower_cost { continue }
			mut branch := -1
			for row in 0 .. rows {
				if block_count[row] > 1 && fixed[row] < 0 { branch = row; break }
			}
			if branch < 0 { continue }
			mut block := block_count[branch] - 1
			for block >= 0 {
				child := fixed.clone()
				child[branch] = block
				stack[stack_size] = child
				stack_size++
				block--
			}
		}
		result := best_cost
		if best_cost == 1000000 { result = -1 }
		if output == nil || capacity < 8 { return -2 }
		mut bytes := []u8{len: 8}
		store_i64_le(mut bytes, result)
		for byte in 0 .. 8 { output[byte] = bytes[byte] }
		return 8
	}
}
