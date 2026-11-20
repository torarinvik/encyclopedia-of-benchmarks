package ruf_schobel_set_cover

import "core:c"

MAX_ROWS :: 6
MAX_COLUMNS :: 8
MAX_INPUT :: c.size_t(17)
MAX_STACK :: 32

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits & 255)
		bits >>= 8
	}
}

interval_cover :: proc(left, right: [MAX_ROWS]int, count: int,
	weights: [MAX_COLUMNS]i64, columns: int, out_cost, out_mask: ^i64) -> bool {
	if count == 0 { out_cost^ = 0; out_mask^ = 0; return true }
	minimum_right, maximum_left := right[0], left[0]
	for i := 1; i < count; i += 1 {
		if right[i] < minimum_right do minimum_right = right[i]
		if left[i] > maximum_left do maximum_left = left[i]
	}
	costs: [MAX_COLUMNS]i64 = {}
	masks: [MAX_COLUMNS]i64 = {}
	for point := 0; point < columns; point += 1 { costs[point] = 1_000_000 }
	for point := 0; point < columns; point += 1 {
		if point <= minimum_right { costs[point] = weights[point]; masks[point] = i64(1) << point }
		for previous := 0; previous < point; previous += 1 {
			if costs[previous] == 1_000_000 do continue
			blocked := false
			for i := 0; i < count; i += 1 {
				if previous < left[i] && right[i] < point { blocked = true; break }
			}
			if blocked do continue
			candidate_cost := costs[previous] + weights[point]
			candidate_mask := masks[previous] | (i64(1) << point)
			if candidate_cost < costs[point] ||
				(candidate_cost == costs[point] && candidate_mask < masks[point]) {
				costs[point] = candidate_cost
				masks[point] = candidate_mask
			}
		}
	}
	best_cost, best_mask := i64(1_000_000), i64(0)
	for point := maximum_left; point < columns; point += 1 {
		if costs[point] < best_cost ||
			(costs[point] == best_cost && costs[point] != 1_000_000 && masks[point] < best_mask) {
			best_cost, best_mask = costs[point], masks[point]
		}
	}
	if best_cost == 1_000_000 do return false
	out_cost^, out_mask^ = best_cost, best_mask
	return true
}

@(export)
ruf_schobel_set_cover :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	rows_raw, columns_raw := input[0], input[1]
	if rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS do return -1
	rows, columns := int(rows_raw), int(columns_raw)
	if length != c.size_t(2 + rows + columns) do return -1
	weights: [MAX_COLUMNS]i64 = {}
	for column := 0; column < columns; column += 1 {
		weight := input[2 + column]
		if weight < 1 || weight > 20 do return -1
		weights[column] = weight
	}
	allowed := (u64(1) << columns) - 1
	row_masks: [MAX_ROWS]u64 = {}
	block_left, block_right: [MAX_ROWS][MAX_COLUMNS]int = {}
	block_count: [MAX_ROWS]int = {}
	for row := 0; row < rows; row += 1 {
		raw := input[2 + columns + row]
		if raw < 0 || (u64(raw) & ~allowed) != 0 do return -1
		row_masks[row] = u64(raw)
		column := 0
		for column < columns {
			if row_masks[row] & (u64(1) << column) == 0 { column += 1; continue }
			block := block_count[row]
			block_left[row][block] = column
			for column + 1 < columns && row_masks[row] & (u64(1) << (column + 1)) != 0 { column += 1 }
			block_right[row][block] = column
			block_count[row] += 1
			column += 1
		}
	}
	for row := 0; row < rows; row += 1 {
		if row_masks[row] == 0 {
			if output == nil || capacity < 8 do return -2
			store_i64_le(output, -1)
			return 8
		}
	}

	best_cost := i64(1_000_000)
	stack: [MAX_STACK][MAX_ROWS]int = {}
	stack_size := 1
	for row := 0; row < rows; row += 1 { stack[0][row] = -1 }
	for stack_size > 0 {
		stack_size -= 1
		fixed := stack[stack_size]
		left, right: [MAX_ROWS]int = {}
		count := 0
		for row := 0; row < rows; row += 1 {
			if block_count[row] == 1 || fixed[row] >= 0 {
				block := 0
				if block_count[row] != 1 { block = fixed[row] }
				left[count], right[count] = block_left[row][block], block_right[row][block]
				count += 1
			}
		}
		lower_cost, lower_mask: i64 = 0, 0
		if !interval_cover(left, right, count, weights, columns, &lower_cost, &lower_mask) do continue
		extra_left, extra_right: [MAX_ROWS]int = {}
		extra_count := 0
		for row := 0; row < rows; row += 1 {
			if row_masks[row] & u64(lower_mask) != 0 do continue
			chosen, chosen_cost := 0, 1_000_000
			for block := 0; block < block_count[row]; block += 1 {
				cheapest := 1_000_000
				for column := block_left[row][block]; column <= block_right[row][block]; column += 1 {
					if int(weights[column]) < cheapest do cheapest = int(weights[column])
				}
				if cheapest < chosen_cost { chosen, chosen_cost = block, cheapest }
			}
			extra_left[extra_count], extra_right[extra_count] = block_left[row][chosen], block_right[row][chosen]
			extra_count += 1
		}
		extra_cost, extra_mask: i64 = 0, 0
		if !interval_cover(extra_left, extra_right, extra_count, weights, columns, &extra_cost, &extra_mask) do continue
		candidate_mask := lower_mask | extra_mask
		candidate_cost := i64(0)
		for column := 0; column < columns; column += 1 {
			if candidate_mask & (i64(1) << column) != 0 do candidate_cost += weights[column]
		}
		if candidate_cost < best_cost do best_cost = candidate_cost
		if best_cost <= lower_cost do continue
		branch := -1
		for row := 0; row < rows; row += 1 {
			if block_count[row] > 1 && fixed[row] < 0 { branch = row; break }
		}
		if branch < 0 do continue
		for block := block_count[branch] - 1; block >= 0; block -= 1 {
			for row := 0; row < rows; row += 1 { stack[stack_size][row] = fixed[row] }
			stack[stack_size][branch] = block
			stack_size += 1
		}
	}
	result := best_cost
	if best_cost == 1_000_000 do result = -1
	if output == nil || capacity < 8 do return -2
	store_i64_le(output, result)
	return 8
}
