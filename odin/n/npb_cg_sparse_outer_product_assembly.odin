package npb_cg_sparse_outer_product_assembly

import "core:c"
import "core:math"

MAX_N :: 16
MAX_NONZER :: 4
MAX_SUPPORT :: 5
MAX_TRIPLETS :: 416
MAX_VALUE_MICRO :: i64(1_000_000)
MAX_SHIFT_MICRO :: i64(10_000_000)
SCALE :: 1_000_000.0
RCOND :: 0.1

write_u64_le :: proc "contextless" (output: [^]u8, offset: ^int, bits: u64) {
	for byte := 0; byte < 8; byte += 1 {
		output[offset^] = u8(bits >> u64(8 * byte))
		offset^ += 1
	}
}

write_f64_le :: proc "contextless" (output: [^]u8, offset: ^int, value: f64) {
	write_u64_le(output, offset, transmute(u64)value)
}

valid :: proc "contextless" (values: [^]i64, length: c.size_t,
		n_out, nonzer_out: ^int) -> bool {
	if values == nil || length < 3 || length > c.size_t(3 + 2 * MAX_N * MAX_NONZER) do return false
	if values[0] < 2 || values[0] > i64(MAX_N) || values[1] < 1 || values[1] > i64(MAX_NONZER) ||
		values[2] < 0 || values[2] > MAX_SHIFT_MICRO do return false
	n := int(values[0]); nonzer := int(values[1])
	if length != c.size_t(3 + 2 * n * nonzer) do return false
	cursor := 3
	for _vector := 0; _vector < n; _vector += 1 {
		seen := u32(0)
		for _entry := 0; _entry < nonzer; _entry += 1 {
			coordinate := values[cursor]; value := values[cursor + 1]; cursor += 2
			if coordinate < 0 || coordinate >= i64(n) || value == 0 ||
				value < -MAX_VALUE_MICRO || value > MAX_VALUE_MICRO do return false
			bit := u32(1) << u32(coordinate)
			if (seen & bit) != 0 do return false
			seen |= bit
		}
	}
	n_out^ = n; nonzer_out^ = nonzer
	return true
}

@(export)
npb_cg_sparse_outer_product_assembly :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	n, nonzer: int
	if !valid(values, length, &n, &nonzer) do return -1
	var raw_rows: [MAX_TRIPLETS]u8 = {}
	var raw_columns: [MAX_TRIPLETS]u8 = {}
	var raw_values: [MAX_TRIPLETS]f64 = {}
	raw_count := 0; cursor := 3
	for vector := 0; vector < n; vector += 1 {
		var coordinates: [MAX_SUPPORT]u8 = {}
		var vector_values: [MAX_SUPPORT]f64 = {}
		support_count := nonzer; has_anchor := false
		for entry := 0; entry < nonzer; entry += 1 {
			coordinate := int(values[cursor])
			coordinates[entry] = u8(coordinate)
			vector_values[entry] = f64(values[cursor + 1]) / SCALE
			cursor += 2
			if coordinate == vector { vector_values[entry] = 0.5; has_anchor = true }
		}
		if !has_anchor { coordinates[support_count] = u8(vector); vector_values[support_count] = 0.5; support_count += 1 }
		weight := f64(1.0)
		if vector == n - 1 { weight = RCOND } else if vector > 0 {
			weight = math.pow_f64(RCOND, f64(vector) / f64(n - 1))
		}
		for column_slot := 0; column_slot < support_count; column_slot += 1 {
			scaled_column := weight * vector_values[column_slot]
			for row_slot := 0; row_slot < support_count; row_slot += 1 {
				raw_rows[raw_count] = coordinates[row_slot]
				raw_columns[raw_count] = coordinates[column_slot]
				raw_values[raw_count] = vector_values[row_slot] * scaled_column
				raw_count += 1
			}
		}
	}
	diagonal_addend := RCOND - f64(values[2]) / SCALE
	for diagonal := 0; diagonal < n; diagonal += 1 {
		raw_rows[raw_count] = u8(diagonal); raw_columns[raw_count] = u8(diagonal)
		raw_values[raw_count] = diagonal_addend; raw_count += 1
	}

	var column_pointers: [MAX_N + 1]i64 = {}
	var row_indices: [MAX_N * MAX_N]u8 = {}
	var matrix_values: [MAX_N * MAX_N]f64 = {}
	nnz := 0
	for column := 0; column < n; column += 1 {
		column_pointers[column] = i64(nnz)
		for row := 0; row < n; row += 1 {
			total := f64(0.0); touched := false
			for triple := 0; triple < raw_count; triple += 1 {
				if int(raw_rows[triple]) == row && int(raw_columns[triple]) == column {
					total += raw_values[triple]; touched = true
				}
			}
			if touched { row_indices[nnz] = u8(row); matrix_values[nnz] = total; nnz += 1 }
		}
	}
	column_pointers[n] = i64(nnz)
	required := 8 * (2 + (n + 1) + 2 * nnz)
	if output == nil || capacity < c.size_t(required) do return -2
	offset := 0
	write_f64_le(output, &offset, f64(n)); write_f64_le(output, &offset, f64(nnz))
	for i := 0; i <= n; i += 1 { write_f64_le(output, &offset, f64(column_pointers[i])) }
	for i := 0; i < nnz; i += 1 { write_f64_le(output, &offset, f64(row_indices[i])) }
	for i := 0; i < nnz; i += 1 { write_f64_le(output, &offset, matrix_values[i]) }
	return i64(required)
}
