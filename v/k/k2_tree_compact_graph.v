const max_n = 32
const max_q = 128
const max_input = 419
const t_bytes = 43
const l_bytes = 128
const t_max_bits = 340
const node_cap = 256

fn bit_get(bits []u8, index int) u8 {
	return (bits[index >> 3] >> (index & 7)) & 1
}

fn bit_set(mut bits []u8, index int) {
	bits[index >> 3] |= u8(1 << (index & 7))
}

fn block_nonempty(rows &i64, row_offset int, n int, row_start int, col_start int, side int) bool {
	mask := ((u64(1) << side) - 1) << col_start
	for row in row_start .. row_start + side {
		if row < n && (u64(rows[row_offset + row]) & mask) != 0 {
			return true
		}
	}
	return false
}

fn build_tree(rows &i64, row_offset int, n int, mut t_bits []u8, mut l_bits []u8,
	mut rank_prefix []u16, mut current_rows []u8, mut current_cols []u8,
	mut next_rows []u8, mut next_cols []u8) (int, int, int) {
	mut side := 2
	mut height := 1
	for side < n {
		side <<= 1
		height++
	}
	mut current_count := 1
	mut current_side := side
	mut t_len := 0
	mut l_len := 0
	current_rows[0] = 0
	current_cols[0] = 0
	for level in 1 .. height + 1 {
		child_side := current_side / 2
		mut next_count := 0
		for parent in 0 .. current_count {
			parent_row := int(current_rows[parent])
			parent_col := int(current_cols[parent])
			for quadrant in 0 .. 4 {
				child_row := parent_row + (quadrant / 2) * child_side
				child_col := parent_col + (quadrant % 2) * child_side
				occupied := block_nonempty(rows, row_offset, n, child_row, child_col, child_side)
				if level < height {
					if occupied {
						bit_set(mut t_bits, t_len)
						next_rows[next_count] = u8(child_row)
						next_cols[next_count] = u8(child_col)
						next_count++
					}
					t_len++
				} else {
					if occupied {
						bit_set(mut l_bits, l_len)
					}
					l_len++
				}
			}
		}
		if level < height {
			for i in 0 .. next_count {
				current_rows[i] = next_rows[i]
				current_cols[i] = next_cols[i]
			}
			current_count = next_count
			current_side = child_side
		}
	}
	rank_prefix[0] = 0
	for i in 0 .. t_len {
		rank_prefix[i + 1] = rank_prefix[i] + u16(bit_get(t_bits, i))
	}
	return t_len, l_len, height
}

fn edge_query(t_bits []u8, l_bits []u8, t_len int, rank_prefix []u16,
	height int, u int, v int) bool {
	mut parent := -1
	mut row_start := 0
	mut col_start := 0
	mut side := 1 << height
	for _ in 0 .. height {
		child_side := side / 2
		row_bit := if u >= row_start + child_side { 1 } else { 0 }
		col_bit := if v >= col_start + child_side { 1 } else { 0 }
		quadrant := 2 * row_bit + col_bit
		child_base := if parent < 0 { 0 } else { 4 * int(rank_prefix[parent + 1]) }
		child := child_base + quadrant
		if row_bit != 0 {
			row_start += child_side
		}
		if col_bit != 0 {
			col_start += child_side
		}
		if child < t_len {
			if bit_get(t_bits, child) == 0 {
				return false
			}
			parent = child
		} else {
			return bit_get(l_bits, child - t_len) != 0
		}
		side = child_side
	}
	return false
}

fn put_i64_le(mut output []u8, offset int, value u64) {
	mut bits := value
	for byte in 0 .. 8 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@[export: 'k2_tree_compact_graph']
pub fn k2_tree_compact_graph(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input {
			return -1
		}
		n_value := input[0]
		if n_value < 1 || n_value > max_n || length < usize(n_value + 2) {
			return -1
		}
		n := int(n_value)
		row_limit := (u64(1) << n) - 1
		for row in 0 .. n {
			if input[1 + row] < 0 || u64(input[1 + row]) > row_limit {
				return -1
			}
		}
		q_index := n + 1
		q_value := input[q_index]
		if q_value < 0 || q_value > max_q {
			return -1
		}
		q := int(q_value)
		if length != usize(n + 2 + 3 * q) {
			return -1
		}
		query_start := n + 2
		for j in 0 .. q {
			op := input[query_start + 3 * j]
			u := input[query_start + 3 * j + 1]
			v := input[query_start + 3 * j + 2]
			if u < 0 || u >= n_value {
				return -1
			}
			if op == 0 {
				if v < 0 || v >= n_value {
					return -1
				}
			} else if op == 1 {
				if v != 0 {
					return -1
				}
			} else {
				return -1
			}
		}
		output_bytes := 8 * (q + 1)
		if output == nil || capacity < usize(output_bytes) {
			return -2
		}

		mut t_bits := []u8{len: t_bytes, init: 0}
		mut l_bits := []u8{len: l_bytes, init: 0}
		mut rank_prefix := []u16{len: t_max_bits + 1, init: 0}
		mut current_rows := []u8{len: node_cap, init: 0}
		mut current_cols := []u8{len: node_cap, init: 0}
		mut next_rows := []u8{len: node_cap, init: 0}
		mut next_cols := []u8{len: node_cap, init: 0}
		t_len, _, height := build_tree(input, 1, n, mut t_bits, mut l_bits,
			mut rank_prefix, mut current_rows, mut current_cols, mut next_rows, mut next_cols)
		mut out_view := output[0..capacity]
		put_i64_le(mut out_view, 0, u64(q))
		for j in 0 .. q {
			op := input[query_start + 3 * j]
			u := int(input[query_start + 3 * j + 1])
			v := int(input[query_start + 3 * j + 2])
			mut result := u64(0)
			if op == 0 {
			if edge_query(t_bits, l_bits, t_len, rank_prefix, height, u, v) {
				result = 1
			}
			} else {
				for successor in 0 .. n {
					if edge_query(t_bits, l_bits, t_len, rank_prefix, height, u, successor) {
						result |= u64(1) << successor
					}
				}
			}
			put_i64_le(mut out_view, 8 * (j + 1), result)
		}
		return i64(output_bytes)
	}
}
