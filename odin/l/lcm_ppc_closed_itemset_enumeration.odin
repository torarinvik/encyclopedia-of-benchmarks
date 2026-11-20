package lcm_ppc_closed_itemset_enumeration

import "core:c"

MAX_ITEMS :: 8
MAX_ROWS :: 16
MAX_WORDS :: 513

lcm_ppc_support :: proc(rows: [^]i64, row_count: int, mask: i64) -> int {
	count := 0
	for row := 0; row < row_count; row += 1 {
		if (rows[row] & mask) == mask { count += 1 }
	}
	return count
}

lcm_ppc_closure :: proc(rows: [^]i64, row_count, item_count: int, mask: i64) -> i64 {
	common := (i64(1) << item_count) - 1
	for row := 0; row < row_count; row += 1 {
		if (rows[row] & mask) == mask { common &= rows[row] }
	}
	return common
}

lcm_ppc_core :: proc(rows: [^]i64, row_count, item_count: int, mask: i64, pattern_support: int) -> int {
	for item := 0; item < item_count; item += 1 {
		prefix_mask := (i64(1) << (item + 1)) - 1
		if lcm_ppc_support(rows, row_count, mask & prefix_mask) == pattern_support { return item }
	}
	return item_count - 1
}

lcm_ppc_put_i64_le :: proc(output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[word*8+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
lcm_ppc_closed_itemset_enumeration :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(3 + MAX_ROWS) do return -1
	item_value, row_value, minimum := input[0], input[1], input[2]
	if item_value < 1 || item_value > MAX_ITEMS || row_value < 1 || row_value > MAX_ROWS ||
		minimum < 1 || minimum > row_value || length != c.size_t(3 + row_value) do return -1
	item_count, row_count := int(item_value), int(row_value)
	limit := i64(1) << item_count
	var rows: [MAX_ROWS]i64
	for row := 0; row < row_count; row += 1 {
		mask := input[3+row]
		if mask < 0 || mask >= limit do return -1
		rows[row] = mask
	}
	row_ptr := &rows[0]

	var words: [MAX_WORDS]i64
	var stack_mask: [MAX_ITEMS+1]i64
	var stack_support: [MAX_ITEMS+1]int
	var stack_core: [MAX_ITEMS+1]int
	var next_item: [MAX_ITEMS+1]int
	var entered: [MAX_ITEMS+1]bool
	stack_mask[0] = lcm_ppc_closure(row_ptr, row_count, item_count, 0)
	stack_support[0] = row_count
	stack_core[0] = -1
	depth, record_count := 0, 0
	active := true
	for active {
		if !entered[depth] {
			words[1+2*record_count] = stack_mask[depth]
			words[2+2*record_count] = i64(stack_support[depth])
			record_count += 1
			entered[depth] = true
			next_item[depth] = stack_core[depth] + 1
		}
		if next_item[depth] >= item_count {
			entered[depth] = false
			if depth == 0 { active = false } else { depth -= 1 }
			continue
		}
		item := next_item[depth]
		next_item[depth] += 1
		bit := i64(1) << item
		parent_mask := stack_mask[depth]
		if (parent_mask & bit) != 0 { continue }
		extended := parent_mask | bit
		child_support := lcm_ppc_support(row_ptr, row_count, extended)
		if child_support < int(minimum) { continue }
		child := lcm_ppc_closure(row_ptr, row_count, item_count, extended)
		lower_prefix := bit - 1
		if (parent_mask & lower_prefix) != (child & lower_prefix) { continue }
		depth += 1
		stack_mask[depth] = child
		stack_support[depth] = child_support
		stack_core[depth] = lcm_ppc_core(row_ptr, row_count, item_count, child, child_support)
		entered[depth] = false
	}

	words[0] = i64(record_count)
	output_bytes := c.size_t(8 * (1 + 2 * record_count))
	if output == nil || capacity < output_bytes do return -2
	for word := 0; word < 1+2*record_count; word += 1 {
		lcm_ppc_put_i64_le(output, word, words[word])
	}
	return i64(output_bytes)
}
