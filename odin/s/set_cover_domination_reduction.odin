package set_cover_domination_reduction

import "core:c"

MAX_ROWS :: 8
MAX_COLUMNS :: 8
MAX_INPUT :: c.size_t(19)
MAX_OUTPUT :: 272

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

column_coverage :: proc(masks: ^[MAX_ROWS]u64, active_rows: ^[MAX_ROWS]bool,
	rows, column: int) -> u64 {
	coverage := u64(0)
	for row := 0; row < rows; row += 1 {
		if active_rows[row] && (masks[row] & (u64(1) << column)) != 0 {
			coverage |= u64(1) << row
		}
	}
	return coverage
}

@(export)
set_cover_domination_reduction :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	rows_raw, columns_raw := input[0], input[1]
	if rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS ||
		length != c.size_t(2+rows_raw+columns_raw) do return -1
	rows, columns := int(rows_raw), int(columns_raw)
	weights: [MAX_COLUMNS]i64 = {}
	masks: [MAX_ROWS]u64 = {}
	active_rows: [MAX_ROWS]bool = {}
	active_columns: [MAX_COLUMNS]bool = {}
	for column := 0; column < columns; column += 1 {
		weight := input[2+column]
		if weight < 1 || weight > 20 do return -1
		weights[column] = weight
		active_columns[column] = true
	}
	valid_columns := (u64(1) << columns) - 1
	for row := 0; row < rows; row += 1 {
		raw := input[2+columns+row]
		if raw < 0 || (u64(raw)&~valid_columns) != 0 do return -1
		masks[row] = u64(raw)
		active_rows[row] = true
	}

	for {
		changed := false
		for keep := 0; keep < rows && !changed; keep += 1 {
			if !active_rows[keep] do continue
			for drop := 0; drop < rows; drop += 1 {
				if !active_rows[drop] || keep == drop do continue
				if (masks[keep]&~masks[drop]) == 0 && (masks[keep] != masks[drop] || keep < drop) {
					active_rows[drop] = false
					changed = true
					break
				}
			}
		}
		if changed do continue

		for drop := 0; drop < columns && !changed; drop += 1 {
			if !active_columns[drop] do continue
			drop_cover := column_coverage(&masks, &active_rows, rows, drop)
			for keep := 0; keep < columns; keep += 1 {
				if !active_columns[keep] || keep == drop do continue
				keep_cover := column_coverage(&masks, &active_rows, rows, keep)
				if (drop_cover&~keep_cover) == 0 && weights[drop] >= weights[keep] &&
					(drop_cover != keep_cover || weights[drop] != weights[keep] || keep < drop) {
					active_columns[drop] = false
					for row := 0; row < rows; row += 1 { masks[row] &= ~(u64(1) << drop) }
					changed = true
					break
				}
			}
		}
		if changed do continue

		for drop := 0; drop < columns && !changed; drop += 1 {
			if !active_columns[drop] do continue
			drop_cover := column_coverage(&masks, &active_rows, rows, drop)
			for keep := 0; keep < columns; keep += 1 {
				if !active_columns[keep] || keep == drop do continue
				keep_cover := column_coverage(&masks, &active_rows, rows, keep)
				exclusive_rows := drop_cover & ~keep_cover
				if (drop_cover&keep_cover) == 0 || exclusive_rows == 0 do continue
				replacement_columns := u64(0)
				feasible := true
				for row := 0; row < rows; row += 1 {
					if (exclusive_rows&(u64(1)<<row)) == 0 do continue
					minimum_column := -1
					for candidate := 0; candidate < columns; candidate += 1 {
						if !active_columns[candidate] || (masks[row]&(u64(1)<<candidate)) == 0 do continue
						if minimum_column < 0 || weights[candidate] < weights[minimum_column] ||
							(weights[candidate] == weights[minimum_column] && candidate < minimum_column) {
							minimum_column = candidate
						}
					}
					if minimum_column < 0 { feasible = false; break }
					replacement_columns |= u64(1) << minimum_column
				}
				replacement_cost := weights[keep]
				for candidate := 0; candidate < columns; candidate += 1 {
					if (replacement_columns&(u64(1)<<candidate)) != 0 do replacement_cost += weights[candidate]
				}
				if feasible && weights[drop] >= replacement_cost {
					active_columns[drop] = false
					for row := 0; row < rows; row += 1 { masks[row] &= ~(u64(1) << drop) }
					changed = true
					break
				}
			}
		}
		if !changed do break
	}

	row_ids: [MAX_ROWS]int = {}
	column_ids: [MAX_COLUMNS]int = {}
	reduced_masks: [MAX_ROWS]u64 = {}
	row_count, column_count := 0, 0
	for row := 0; row < rows; row += 1 { if active_rows[row] { row_ids[row_count] = row; row_count += 1 } }
	for column := 0; column < columns; column += 1 { if active_columns[column] { column_ids[column_count] = column; column_count += 1 } }
	for i := 0; i < row_count; i += 1 {
		for j := 0; j < column_count; j += 1 {
			if (masks[row_ids[i]]&(u64(1)<<column_ids[j])) != 0 do reduced_masks[i] |= u64(1) << j
		}
	}
	words := 2 + 2*row_count + 2*column_count
	byte_count := 8 * words
	staged: [MAX_OUTPUT]u8 = {}
	cursor := 0
	store_i64_le(&staged[0],8*cursor,i64(row_count)); cursor += 1
	store_i64_le(&staged[0],8*cursor,i64(column_count)); cursor += 1
	for i := 0; i < row_count; i += 1 { store_i64_le(&staged[0],8*cursor,i64(row_ids[i])); cursor += 1 }
	for i := 0; i < column_count; i += 1 { store_i64_le(&staged[0],8*cursor,i64(column_ids[i])); cursor += 1 }
	for i := 0; i < column_count; i += 1 { store_i64_le(&staged[0],8*cursor,weights[column_ids[i]]); cursor += 1 }
	for i := 0; i < row_count; i += 1 { store_i64_le(&staged[0],8*cursor,i64(reduced_masks[i])); cursor += 1 }
	if output == nil || capacity < c.size_t(byte_count) do return -2
	for byte := 0; byte < byte_count; byte += 1 { output[byte] = staged[byte] }
	return i64(byte_count)
}
