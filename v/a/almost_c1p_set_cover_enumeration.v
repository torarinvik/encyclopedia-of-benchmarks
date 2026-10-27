module almost_c1p_set_cover_enumeration

import core.c

const max_rows = 8
const max_columns = 10
const max_output_bytes = 80

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'almost_c1p_set_cover_enumeration']
pub fn almost_c1p_set_cover_enumeration(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 21 { return -1 }
		rows_raw := input[0]
		columns_raw := input[1]
		if rows_raw < 1 || rows_raw > max_rows || columns_raw < 1 || columns_raw > max_columns || length != usize(2 + rows_raw + columns_raw) { return -1 }
		rows := int(rows_raw)
		columns := int(columns_raw)
		mut weights := [max_columns]i64{}
		for column in 0 .. columns {
			weight := input[2 + column]
			if weight < 1 || weight > 20 { return -1 }
			weights[column] = weight
		}
		valid_mask := (u64(1) << columns) - 1
		mut row_masks := [max_rows]u64{}
		for row in 0 .. rows {
			raw_mask := input[2 + columns + row]
			if raw_mask < 0 || (u64(raw_mask) & ~valid_mask) != 0 { return -1 }
			row_masks[row] = u64(raw_mask)
		}

		state_count := 1 << columns
		mut feasible := [1 << max_columns]bool{}
		feasible[0] = true
		for row in 0 .. rows {
			cover_mask := row_masks[row]
			for selected in 0 .. state_count {
				if !feasible[selected] || (u64(selected) & cover_mask) != 0 { continue }
				feasible[selected] = false
				for column in 0 .. columns {
					bit := 1 << column
					if (cover_mask & u64(bit)) != 0 { feasible[selected | bit] = true }
				}
			}
		}

		mut best_found := false
		mut best_mask := u64(0)
		mut best_cost := i64(0)
		for selected in 0 .. state_count {
			if !feasible[selected] { continue }
			mut cost := i64(0)
			for column in 0 .. columns { if (u64(selected) & (u64(1) << column)) != 0 { cost += weights[column] } }
			mask := u64(selected)
			if !best_found || cost < best_cost || (cost == best_cost && mask < best_mask) {
				best_found = true
				best_mask = mask
				best_cost = cost
			}
		}
		mut selected_count := 0
		if best_found { for column in 0 .. columns { if (best_mask & (u64(1) << column)) != 0 { selected_count++ } } }
		output_bytes := if best_found { 8 * (selected_count + 2) } else { 8 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		if best_found {
			put_i64(mut staged[..], 0, i64(selected_count))
			mut cursor := 1
			for column in 0 .. columns {
				if (best_mask & (u64(1) << column)) != 0 { put_i64(mut staged[..], 8 * cursor, i64(column)); cursor++ }
			}
			put_i64(mut staged[..], 8 * cursor, best_cost)
		} else { put_i64(mut staged[..], 0, -1) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
