module lcm_ppc_closed_itemset_enumeration

const (
	max_items = 8
	max_rows = 16
	max_words = 513
)

fn lcm_ppc_support(rows &[max_rows]i64, row_count int, mask i64) int {
	mut count := 0
	for row in 0 .. row_count {
		if rows[row] & mask == mask { count++ }
	}
	return count
}

fn lcm_ppc_closure(rows &[max_rows]i64, row_count int, item_count int, mask i64) i64 {
	mut common := (i64(1) << item_count) - 1
	for row in 0 .. row_count {
		if rows[row] & mask == mask { common &= rows[row] }
	}
	return common
}

fn lcm_ppc_core(rows &[max_rows]i64, row_count int, item_count int,
		mask i64, pattern_support int) int {
	for item in 0 .. item_count {
		prefix_mask := (i64(1) << (item + 1)) - 1
		if lcm_ppc_support(rows, row_count, mask & prefix_mask) == pattern_support { return item }
	}
	return item_count - 1
}

fn lcm_ppc_put_i64(mut output &u8, word int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[word * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'lcm_ppc_closed_itemset_enumeration']
pub fn lcm_ppc_closed_itemset_enumeration(input &i64, length usize, mut output &u8,
		capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 3 + max_rows { return -1 }
		item_value, row_value, minimum := input[0], input[1], input[2]
		if item_value < 1 || item_value > max_items || row_value < 1 || row_value > max_rows ||
			minimum < 1 || minimum > row_value || length != usize(3 + row_value) { return -1 }
		item_count, row_count := int(item_value), int(row_value)
		limit := i64(1) << item_count
		mut rows := [max_rows]i64{}
		for row in 0 .. row_count {
			mask := input[3 + row]
			if mask < 0 || mask >= limit { return -1 }
			rows[row] = mask
		}

		mut words := [max_words]i64{}
		mut stack_mask := [max_items + 1]i64{}
		mut stack_support := [max_items + 1]int{}
		mut stack_core := [max_items + 1]int{}
		mut next_item := [max_items + 1]int{}
		mut entered := [max_items + 1]bool{}
		stack_mask[0] = lcm_ppc_closure(&rows, row_count, item_count, 0)
		stack_support[0] = row_count
		stack_core[0] = -1
		mut depth, mut record_count := 0, 0
		mut active := true
		for active {
			if !entered[depth] {
				words[1 + 2 * record_count] = stack_mask[depth]
				words[2 + 2 * record_count] = i64(stack_support[depth])
				record_count++
				entered[depth] = true
				next_item[depth] = stack_core[depth] + 1
			}
			if next_item[depth] >= item_count {
				entered[depth] = false
				if depth == 0 { active = false } else { depth-- }
				continue
			}
			item := next_item[depth]
			next_item[depth]++
			bit := i64(1) << item
			parent_mask := stack_mask[depth]
			if parent_mask & bit != 0 { continue }
			extended := parent_mask | bit
			child_support := lcm_ppc_support(&rows, row_count, extended)
			if child_support < int(minimum) { continue }
			child := lcm_ppc_closure(&rows, row_count, item_count, extended)
			lower_prefix := bit - 1
			if parent_mask & lower_prefix != child & lower_prefix { continue }
			depth++
			stack_mask[depth] = child
			stack_support[depth] = child_support
			stack_core[depth] = lcm_ppc_core(&rows, row_count, item_count, child, child_support)
			entered[depth] = false
		}

		words[0] = i64(record_count)
		output_bytes := 8 * (1 + 2 * record_count)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for word in 0 .. 1 + 2 * record_count { lcm_ppc_put_i64(mut output, word, words[word]) }
		return i64(output_bytes)
	}
}
