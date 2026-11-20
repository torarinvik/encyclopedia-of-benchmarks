module three_dimensional_bird_baker_matching
import core.c

const max_dim = 5
const max_pat_dim = 4
const max_input = 196
const max_matches = 125

fn put_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn same_rows(plane []i64, left int, right int, width int) bool {
	for column in 0 .. width { if plane[left * width + column] != plane[right * width + column] { return false } }
	true
}

@[export: 'three_dimensional_bird_baker_matching']
pub fn three_dimensional_bird_baker_matching(input &i64, length usize,
	output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 7 || length > max_input { return -1 }
		r0, c0, d0 := input[0], input[1], input[2]
		pr0, pc0, pd0 := input[3], input[4], input[5]
		if r0 < 1 || r0 > 5 || c0 < 1 || c0 > 5 || d0 < 1 || d0 > 5 || pr0 < 1 || pr0 > 4 || pc0 < 1 || pc0 > 4 || pd0 < 1 || pd0 > 4 || pr0 > r0 || pc0 > c0 || pd0 > d0 { return -1 }
		rows, columns, depths := int(r0), int(c0), int(d0)
		p_rows, p_columns, p_depths := int(pr0), int(pc0), int(pd0)
		text_size := rows * columns * depths
		pattern_size := p_rows * p_columns * p_depths
		if int(length) != 6 + text_size + pattern_size { return -1 }
		mut text := []i64{len: max_dim * max_dim * max_dim, init: 0}
		mut pattern := []i64{len: max_pat_dim * max_pat_dim * max_pat_dim, init: 0}
		for i in 0 .. text_size {
			text[i] = input[6 + i]
			if text[i] < 0 || text[i] > 3 { return -1 }
		}
		for i in 0 .. pattern_size {
			pattern[i] = input[6 + text_size + i]
			if pattern[i] < 0 || pattern[i] > 3 { return -1 }
		}
		mut plane_ids := []int{len: max_pat_dim, init: 0}
		mut unique_planes := []i64{len: max_pat_dim * max_pat_dim * max_pat_dim, init: 0}
		plane_area := p_rows * p_columns
		mut unique_count := 0
		for pz in 0 .. p_depths {
			mut found := unique_count
			for candidate in 0 .. unique_count {
				mut equal := true
				for i in 0 .. plane_area { if unique_planes[candidate * 16 + i] != pattern[pz * plane_area + i] { equal = false } }
				if equal { found = candidate; break }
			}
			if found == unique_count {
				for i in 0 .. plane_area { unique_planes[unique_count * 16 + i] = pattern[pz * plane_area + i] }
				unique_count++
			}
			plane_ids[pz] = found
		}
		row_starts := rows - p_rows + 1
		column_starts := columns - p_columns + 1
		mut labels := []int{len: max_dim * max_dim * max_dim, init: -1}
		for z in 0 .. depths {
			for unique in 0 .. unique_count {
				mut marks := []bool{len: max_dim * max_dim * max_pat_dim, init: false}
				mut prefix := []int{len: max_pat_dim, init: 0}
				plane := unique_planes[unique * 16..unique * 16 + 16]
				for i in 1 .. p_rows {
					mut matched := prefix[i - 1]
					for matched > 0 && !same_rows(plane, i, matched, p_columns) { matched = prefix[matched - 1] }
					if same_rows(plane, i, matched, p_columns) { matched++ }
					prefix[i] = matched
				}
				for row in 0 .. rows {
					for col in 0 .. column_starts {
						for p_row in 0 .. p_rows {
							mut equal := true
							for p_col in 0 .. p_columns { if text[(z * rows + row) * columns + col + p_col] != plane[p_row * p_columns + p_col] { equal = false } }
							marks[(row * max_dim + col) * max_pat_dim + p_row] = equal
						}
					}
				}
				for col in 0 .. column_starts {
					mut matched := 0
					for row in 0 .. rows {
						for matched > 0 && !marks[(row * max_dim + col) * max_pat_dim + matched] { matched = prefix[matched - 1] }
						if marks[(row * max_dim + col) * max_pat_dim + matched] { matched++ }
						if matched == p_rows {
							labels[(z * max_dim + row + 1 - p_rows) * max_dim + col] = unique
							matched = prefix[matched - 1]
						}
					}
				}
			}
		}
		mut depth_prefix := []int{len: max_pat_dim, init: 0}
		for i in 1 .. p_depths {
			mut matched := depth_prefix[i - 1]
			for matched > 0 && plane_ids[i] != plane_ids[matched] { matched = depth_prefix[matched - 1] }
			if plane_ids[i] == plane_ids[matched] { matched++ }
			depth_prefix[i] = matched
		}
		mut matches := []i64{len: max_matches * 3, init: 0}
		mut count := 0
		for row in 0 .. row_starts {
			for col in 0 .. column_starts {
				mut matched := 0
				for z in 0 .. depths {
					token := labels[(z * max_dim + row) * max_dim + col]
					for matched > 0 && token != plane_ids[matched] { matched = depth_prefix[matched - 1] }
					if token == plane_ids[matched] { matched++ }
					if matched == p_depths {
						matches[count * 3] = i64(row)
						matches[count * 3 + 1] = i64(col)
						matches[count * 3 + 2] = i64(z + 1 - p_depths)
						count++
						matched = depth_prefix[matched - 1]
					}
				}
			}
		}
		bytes := 8 * (1 + 3 * count)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_le(output, 0, i64(count))
		for i in 0 .. 3 * count { put_le(output, 8 * (i + 1), matches[i]) }
		return i64(bytes)
	}
}
