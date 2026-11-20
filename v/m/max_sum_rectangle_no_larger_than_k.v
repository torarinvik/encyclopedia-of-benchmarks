module main

const max_rows = 8
const max_columns = 8
const no_feasible = i64(-1025)
const invalid_input = i64(-1026)

fn best_subarray_at_most(values []i64, limit i64) i64 {
	mut prefixes := []i64{len: values.len + 1, cap: values.len + 1, init: 0}
	mut prefix_count := 1
	mut running := i64(0)
	mut best := no_feasible
	for value in values {
		running += value
		threshold := running - limit
		mut low := 0
		mut high := prefix_count
		for low < high {
			middle := low + (high - low) / 2
			if prefixes[middle] < threshold { low = middle + 1 } else { high = middle }
		}
		if low < prefix_count {
			candidate := running - prefixes[low]
			if best == no_feasible || candidate > best { best = candidate }
		}
		mut insert := prefix_count
		for insert > 0 && prefixes[insert - 1] > running {
			prefixes[insert] = prefixes[insert - 1]
			insert--
		}
		prefixes[insert] = running
		prefix_count++
	}
	return best
}

@[export: 'max_sum_rectangle_no_larger_than_k']
pub fn max_sum_rectangle_no_larger_than_k(input &i64, length usize) i64 {
	if length < 3 || length > 68 { return invalid_input }
	unsafe {
		if input == nil { return invalid_input }
		rows_value := input[0]
		columns_value := input[1]
		limit := input[2]
		if rows_value < 1 || rows_value > max_rows || columns_value < 1 || columns_value > max_columns
			|| limit < -1024 || limit > 1024 { return invalid_input }
		rows := int(rows_value)
		columns := int(columns_value)
		if length != usize(3 + rows * columns) { return invalid_input }
		mut matrix := [max_rows][max_columns]i64{}
		for row in 0 .. rows {
			for column in 0 .. columns {
				value := input[3 + row * columns + column]
				if value < -16 || value > 16 { return invalid_input }
				matrix[row][column] = value
			}
		}
		short_dimension := if rows < columns { rows } else { columns }
		long_dimension := if rows < columns { columns } else { rows }
		mut best := no_feasible
		for first in 0 .. short_dimension {
			mut compressed := []i64{len: long_dimension, init: 0}
			for last in first .. short_dimension {
				for offset in 0 .. long_dimension {
					if rows <= columns { compressed[offset] += matrix[last][offset] }
					else { compressed[offset] += matrix[offset][last] }
				}
				candidate := best_subarray_at_most(compressed, limit)
				if candidate != no_feasible && (best == no_feasible || candidate > best) {
					best = candidate
					if best == limit { return best }
				}
			}
		}
		return best
	}
}
