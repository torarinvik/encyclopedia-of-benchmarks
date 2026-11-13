package sparse_supernodal_cholesky

import "core:c"
import "core:math"

@(export)
sparse_supernodal_cholesky :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 56 do return -1
	if input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > input[0] do return -1
	n, count := int(input[0]), int(input[1])
	triangle := n * (n + 1) / 2
	if length != c.size_t(3 + count + n + triangle) do return -1
	boundary: [9]int
	masks: [8]int
	slot: [8][8]int
	for i := 0; i <= count; i += 1 {
		if input[2+i] < 0 || input[2+i] > i64(n) do return -1
		boundary[i] = int(input[2+i])
		if i > 0 && boundary[i] <= boundary[i-1] do return -1
	}
	if boundary[0] != 0 || boundary[count] != n do return -1
	for row := 0; row < n; row += 1 {
		mask := input[3+count+row]
		if mask < 0 || mask >= (i64(1) << (row+1)) || (mask & (i64(1) << row)) == 0 do return -1
		masks[row] = int(mask)
		for col := 0; col < n; col += 1 do slot[row][col] = -1
	}
	for col := 0; col < n; col += 1 {
		for row := col+1; row < n; row += 1 {
			if masks[row] & (1 << col) == 0 do continue
			for lower := row+1; lower < n; lower += 1 {
				if masks[lower] & (1 << col) != 0 && masks[lower] & (1 << row) == 0 do return -1
			}
		}
	}
	for block := 0; block < count; block += 1 {
		start, end := boundary[block], boundary[block+1]
		for row := start; row < end; row += 1 {
			for col := start; col < row; col += 1 {
				if masks[row] & (1 << col) == 0 do return -1
			}
		}
		bits := ((1 << end) - 1) ~ ((1 << start) - 1)
		for row := end; row < n; row += 1 {
			selected := masks[row] & bits
			if selected != 0 && selected != bits do return -1
		}
	}
	sparse: [36]f64
	cursor, used := 3+count+n, 0
	for row := 0; row < n; row += 1 {
		for col := 0; col <= row; col += 1 {
			value := input[cursor]
			cursor += 1
			if value < -1_000_000 || value > 1_000_000 do return -1
			if masks[row] & (1 << col) == 0 {
				if value != 0 do return -1
			} else {
				slot[row][col] = used
				sparse[used] = f64(value) / 1000.0
				used += 1
			}
		}
	}
	for block := 0; block < count; block += 1 {
		start, end := boundary[block], boundary[block+1]
		for col := start; col < end; col += 1 {
			pivot := sparse[slot[col][col]]
			if !math.is_finite(pivot) || pivot <= 0 do return -1
			sparse[slot[col][col]] = math.sqrt_f64(pivot)
			for row := col+1; row < end; row += 1 do sparse[slot[row][col]] /= sparse[slot[col][col]]
			for row := col+1; row < end; row += 1 {
				for target := col+1; target <= row; target += 1 {
					sparse[slot[row][target]] -= sparse[slot[row][col]] * sparse[slot[target][col]]
				}
			}
		}
		for row := end; row < n; row += 1 {
			if masks[row] & (1 << start) == 0 do continue
			for col := start; col < end; col += 1 {
				value := sparse[slot[row][col]]
				for k := start; k < col; k += 1 do value -= sparse[slot[row][k]] * sparse[slot[col][k]]
				sparse[slot[row][col]] = value / sparse[slot[col][col]]
			}
		}
		for row := end; row < n; row += 1 {
			if masks[row] & (1 << start) == 0 do continue
			for target := end; target <= row; target += 1 {
				if masks[target] & (1 << start) == 0 do continue
				for k := start; k < end; k += 1 {
					sparse[slot[row][target]] -= sparse[slot[row][k]] * sparse[slot[target][k]]
				}
			}
		}
	}
	required := triangle * 8
	if output == nil || capacity < c.size_t(required) do return -2
	offset := 0
	for row := 0; row < n; row += 1 {
		for col := 0; col <= row; col += 1 {
			value := f64(0)
			if slot[row][col] >= 0 do value = sparse[slot[row][col]]
			bits := transmute(u64)value
			for byte := 0; byte < 8; byte += 1 {
				output[offset] = u8(bits >> u64(8*byte))
				offset += 1
			}
		}
	}
	return i64(required)
}
