import math

const max_n = 16
const max_nonzer = 4
const max_support = 5
const max_triplets = 416
const max_value_micro = i64(1_000_000)
const max_shift_micro = i64(10_000_000)
const scale = 1_000_000.0
const rcond = 0.1

fn write_u64_le(mut output &u8, offset int, bits u64) {
	unsafe {
		for byte in 0 .. 8 {
			output[offset] = u8((bits >> (8 * byte)) & 255)
		}
	}
}

fn valid(values &i64, length usize) (int, int, bool) {
	unsafe {
		if values == nil || length < 3 || length > usize(3 + 2 * max_n * max_nonzer) {
			return 0, 0, false
		}
		if values[0] < 2 || values[0] > i64(max_n) || values[1] < 1 || values[1] > i64(max_nonzer) ||
			values[2] < 0 || values[2] > max_shift_micro { return 0, 0, false }
		n := int(values[0]); nonzer := int(values[1])
		if length != usize(3 + 2 * n * nonzer) { return 0, 0, false }
		mut cursor := 3
		for _ in 0 .. n {
			mut seen := u32(0)
			for _ in 0 .. nonzer {
				coordinate := values[cursor]; value := values[cursor + 1]; cursor += 2
				if coordinate < 0 || coordinate >= i64(n) || value == 0 ||
					value < -max_value_micro || value > max_value_micro { return 0, 0, false }
				bit := u32(1) << u32(coordinate)
				if seen & bit != 0 { return 0, 0, false }
				seen |= bit
			}
		}
		return n, nonzer, true
	}
}

@[export: 'npb_cg_sparse_outer_product_assembly']
pub fn npb_cg_sparse_outer_product_assembly(values &i64, length usize, mut output &u8, capacity usize) i64 {
	n, nonzer, ok := valid(values, length)
	if !ok { return -1 }
	mut raw_rows := [max_triplets]u8{}
	mut raw_columns := [max_triplets]u8{}
	mut raw_values := [max_triplets]f64{}
	mut raw_count := 0
	mut cursor := 3
	unsafe {
		for vector in 0 .. n {
			mut coordinates := [max_support]u8{}
			mut vector_values := [max_support]f64{}
			mut support_count := nonzer
			mut has_anchor := false
			for entry in 0 .. nonzer {
				coordinate := int(values[cursor])
				coordinates[entry] = u8(coordinate)
				vector_values[entry] = f64(values[cursor + 1]) / scale
				cursor += 2
				if coordinate == vector { vector_values[entry] = 0.5; has_anchor = true }
			}
			if !has_anchor { coordinates[support_count] = u8(vector); vector_values[support_count] = 0.5; support_count++ }
			weight := 1.0
			if vector == n - 1 { weight = rcond } else if vector > 0 {
				weight = math.pow(rcond, f64(vector) / f64(n - 1))
			}
			for column_slot in 0 .. support_count {
				scaled_column := weight * vector_values[column_slot]
				for row_slot in 0 .. support_count {
					raw_rows[raw_count] = coordinates[row_slot]
					raw_columns[raw_count] = coordinates[column_slot]
					raw_values[raw_count] = vector_values[row_slot] * scaled_column
					raw_count++
				}
			}
		}
		diagonal_addend := rcond - f64(values[2]) / scale
		for diagonal in 0 .. n {
			raw_rows[raw_count] = u8(diagonal); raw_columns[raw_count] = u8(diagonal)
			raw_values[raw_count] = diagonal_addend; raw_count++
		}
	}

	mut column_pointers := [max_n + 1]i64{}
	mut row_indices := [max_n * max_n]u8{}
	mut matrix_values := [max_n * max_n]f64{}
	mut nnz := 0
	unsafe {
		for column in 0 .. n {
			column_pointers[column] = i64(nnz)
			for row in 0 .. n {
				mut total := 0.0
				mut touched := false
				for triple in 0 .. raw_count {
					if int(raw_rows[triple]) == row && int(raw_columns[triple]) == column {
						total += raw_values[triple]
						touched = true
					}
				}
				if touched { row_indices[nnz] = u8(row); matrix_values[nnz] = total; nnz++ }
			}
		}
		column_pointers[n] = i64(nnz)
	}
	required := 8 * (2 + (n + 1) + 2 * nnz)
	if unsafe { output == nil } || capacity < required { return -2 }
	mut offset := 0
	unsafe {
		write_u64_le(mut output, offset, math.bits_from_f64(f64(n))); offset += 8
		write_u64_le(mut output, offset, math.bits_from_f64(f64(nnz))); offset += 8
		for i in 0 .. n + 1 { write_u64_le(mut output, offset, math.bits_from_f64(f64(column_pointers[i]))); offset += 8 }
		for i in 0 .. nnz { write_u64_le(mut output, offset, math.bits_from_f64(f64(row_indices[i]))); offset += 8 }
		for i in 0 .. nnz { write_u64_le(mut output, offset, math.bits_from_f64(matrix_values[i])); offset += 8 }
	}
	i64(required)
}
