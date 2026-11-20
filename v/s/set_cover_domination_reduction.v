module set_cover_domination_reduction

const max_rows = 8
const max_columns = 8
const max_input = 19
const max_output = 272

fn store_i64_le(mut output []u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn column_coverage(masks []u64, active_rows []bool, rows int, column int) u64 {
	mut coverage := u64(0)
	for row in 0 .. rows {
		if active_rows[row] && (masks[row] & (u64(1) << column)) != 0 {
			coverage |= u64(1) << row
		}
	}
	return coverage
}

@[export: 'set_cover_domination_reduction']
pub fn set_cover_domination_reduction(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		rows_raw := input[0]
		columns_raw := input[1]
		if rows_raw < 1 || rows_raw > max_rows || columns_raw < 1 || columns_raw > max_columns ||
			length != usize(2 + rows_raw + columns_raw) { return -1 }
		rows := int(rows_raw)
		columns := int(columns_raw)
		mut weights := []i64{len: max_columns}
		mut masks := []u64{len: max_rows}
		mut active_rows := []bool{len: max_rows}
		mut active_columns := []bool{len: max_columns}
		for column in 0 .. columns {
			weight := input[2 + column]
			if weight < 1 || weight > 20 { return -1 }
			weights[column] = weight
			active_columns[column] = true
		}
		valid_columns := (u64(1) << columns) - 1
		for row in 0 .. rows {
			raw := input[2 + columns + row]
			if raw < 0 || (u64(raw) & ~valid_columns) != 0 { return -1 }
			masks[row] = u64(raw)
			active_rows[row] = true
		}

		for {
			mut changed := false
			for keep in 0 .. rows {
				if !active_rows[keep] { continue }
				for drop in 0 .. rows {
					if !active_rows[drop] || keep == drop { continue }
					if (masks[keep] & ~masks[drop]) == 0 && (masks[keep] != masks[drop] || keep < drop) {
						active_rows[drop] = false
						changed = true
						break
					}
				}
				if changed { break }
			}
			if changed { continue }

			for drop in 0 .. columns {
				if !active_columns[drop] { continue }
				drop_cover := column_coverage(masks, active_rows, rows, drop)
				for keep in 0 .. columns {
					if !active_columns[keep] || keep == drop { continue }
					keep_cover := column_coverage(masks, active_rows, rows, keep)
					if (drop_cover & ~keep_cover) == 0 && weights[drop] >= weights[keep] &&
						(drop_cover != keep_cover || weights[drop] != weights[keep] || keep < drop) {
						active_columns[drop] = false
						for row in 0 .. rows { masks[row] &= ~(u64(1) << drop) }
						changed = true
						break
					}
				}
				if changed { break }
			}
			if changed { continue }

			for drop in 0 .. columns {
				if !active_columns[drop] { continue }
				drop_cover := column_coverage(masks, active_rows, rows, drop)
				for keep in 0 .. columns {
					if !active_columns[keep] || keep == drop { continue }
					keep_cover := column_coverage(masks, active_rows, rows, keep)
					exclusive_rows := drop_cover & ~keep_cover
					if (drop_cover & keep_cover) == 0 || exclusive_rows == 0 { continue }
					mut replacement_columns := u64(0)
					mut feasible := true
					for row in 0 .. rows {
						if (exclusive_rows & (u64(1) << row)) == 0 { continue }
						mut minimum_column := -1
						for candidate in 0 .. columns {
							if !active_columns[candidate] || (masks[row] & (u64(1) << candidate)) == 0 { continue }
							if minimum_column < 0 || weights[candidate] < weights[minimum_column] ||
								(weights[candidate] == weights[minimum_column] && candidate < minimum_column) {
								minimum_column = candidate
							}
						}
						if minimum_column < 0 { feasible = false; break }
						replacement_columns |= u64(1) << minimum_column
					}
					mut replacement_cost := weights[keep]
					for candidate in 0 .. columns {
						if (replacement_columns & (u64(1) << candidate)) != 0 { replacement_cost += weights[candidate] }
					}
					if feasible && weights[drop] >= replacement_cost {
						active_columns[drop] = false
						for row in 0 .. rows { masks[row] &= ~(u64(1) << drop) }
						changed = true
						break
					}
				}
				if changed { break }
			}
			if !changed { break }
		}

		mut row_ids := []int{}
		mut column_ids := []int{}
		for row in 0 .. rows { if active_rows[row] { row_ids << row } }
		for column in 0 .. columns { if active_columns[column] { column_ids << column } }
		mut reduced_masks := []u64{len: row_ids.len}
		for i, row in row_ids {
			for j, column in column_ids {
				if (masks[row] & (u64(1) << column)) != 0 { reduced_masks[i] |= u64(1) << j }
			}
		}
		words := 2 + 2 * row_ids.len + 2 * column_ids.len
		bytes := 8 * words
		mut staged := []u8{len: max_output}
		mut cursor := 0
		store_i64_le(mut staged, 8 * cursor, i64(row_ids.len)); cursor++
		store_i64_le(mut staged, 8 * cursor, i64(column_ids.len)); cursor++
		for row in row_ids { store_i64_le(mut staged, 8 * cursor, i64(row)); cursor++ }
		for column in column_ids { store_i64_le(mut staged, 8 * cursor, i64(column)); cursor++ }
		for column in column_ids { store_i64_le(mut staged, 8 * cursor, weights[column]); cursor++ }
		for mask in reduced_masks { store_i64_le(mut staged, 8 * cursor, i64(mask)); cursor++ }
		if output == nil || capacity < usize(bytes) { return -2 }
		for byte in 0 .. bytes { output[byte] = staged[byte] }
		return i64(bytes)
	}
}
