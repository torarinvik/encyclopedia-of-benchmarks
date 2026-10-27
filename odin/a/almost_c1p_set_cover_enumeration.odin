package almost_c1p_set_cover_enumeration

import "core:c"

MAX_ROWS :: 8
MAX_COLUMNS :: 10
MAX_OUTPUT_BYTES :: 80

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
almost_c1p_set_cover_enumeration :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 21 do return -1
	rows_raw, columns_raw := input[0], input[1]
	if rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS || length != c.size_t(2+rows_raw+columns_raw) do return -1
	rows, columns := int(rows_raw), int(columns_raw)
	weights: [MAX_COLUMNS]i64 = {}
	for column := 0; column < columns; column += 1 {
		weight := input[2+column]
		if weight < 1 || weight > 20 do return -1
		weights[column] = weight
	}
	valid_mask := (u64(1) << columns) - 1
	row_masks: [MAX_ROWS]u64 = {}
	for row := 0; row < rows; row += 1 {
		raw_mask := input[2+columns+row]
		if raw_mask < 0 || (u64(raw_mask)&~valid_mask) != 0 do return -1
		row_masks[row] = u64(raw_mask)
	}

	state_count := 1 << columns
	feasible: [1 << MAX_COLUMNS]bool = {}
	feasible[0] = true
	for row := 0; row < rows; row += 1 {
		cover_mask := row_masks[row]
		for selected := 0; selected < state_count; selected += 1 {
			if !feasible[selected] || (u64(selected)&cover_mask) != 0 do continue
			feasible[selected] = false
			for column := 0; column < columns; column += 1 {
				bit := 1 << column
				if (cover_mask&u64(bit)) != 0 do feasible[selected|bit] = true
			}
		}
	}

	best_found := false
	best_mask: u64 = 0
	best_cost: i64 = 0
	for selected := 0; selected < state_count; selected += 1 {
		if !feasible[selected] do continue
		cost: i64 = 0
		for column := 0; column < columns; column += 1 { if (u64(selected)&(u64(1)<<column)) != 0 do cost += weights[column] }
		mask := u64(selected)
		if !best_found || cost < best_cost || (cost == best_cost && mask < best_mask) {
			best_found = true
			best_mask = mask
			best_cost = cost
		}
	}
	selected_count := 0
	if best_found { for column := 0; column < columns; column += 1 { if (best_mask&(u64(1)<<column)) != 0 do selected_count += 1 } }
	output_bytes := if best_found { 8*(selected_count+2) } else { 8 }
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	if best_found {
		store_i64_le(&staged[0],0,i64(selected_count))
		cursor := 1
		for column := 0; column < columns; column += 1 { if (best_mask&(u64(1)<<column)) != 0 { store_i64_le(&staged[0],8*cursor,i64(column)); cursor += 1 } }
		store_i64_le(&staged[0],8*cursor,best_cost)
	} else { store_i64_le(&staged[0],0,-1) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
