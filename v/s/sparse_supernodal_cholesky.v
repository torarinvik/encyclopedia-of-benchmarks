module main

import math

@[export: 'sparse_supernodal_cholesky']
pub fn sparse_supernodal_cholesky(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 56 { return -1 }
		if input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > input[0] { return -1 }
		n := int(input[0])
		count := int(input[1])
		triangle := n * (n + 1) / 2
		if length != usize(3 + count + n + triangle) { return -1 }
		mut boundary := [9]int{}
		mut masks := [8]int{}
		mut slots := [8][8]int{}
		for i in 0 .. count + 1 {
			if input[2 + i] < 0 || input[2 + i] > n { return -1 }
			boundary[i] = int(input[2 + i])
			if i > 0 && boundary[i] <= boundary[i - 1] { return -1 }
		}
		if boundary[0] != 0 || boundary[count] != n { return -1 }
		for row in 0 .. n {
			mask := input[3 + count + row]
			if mask < 0 || mask >= (i64(1) << (row + 1)) || mask & (i64(1) << row) == 0 { return -1 }
			masks[row] = int(mask)
			for col in 0 .. n { slots[row][col] = -1 }
		}
		for col in 0 .. n {
			for row in col + 1 .. n {
				if masks[row] & (1 << col) == 0 { continue }
				for lower in row + 1 .. n {
					if masks[lower] & (1 << col) != 0 && masks[lower] & (1 << row) == 0 { return -1 }
				}
			}
		}
		for block in 0 .. count {
			start := boundary[block]
			end := boundary[block + 1]
			for row in start .. end {
				for col in start .. row {
					if masks[row] & (1 << col) == 0 { return -1 }
				}
			}
			bits := ((1 << end) - 1) ^ ((1 << start) - 1)
			for row in end .. n {
				selected := masks[row] & bits
				if selected != 0 && selected != bits { return -1 }
			}
		}
		mut sparse := [36]f64{}
		mut cursor := 3 + count + n
		mut used := 0
		for row in 0 .. n {
			for col in 0 .. row + 1 {
				value := input[cursor]
				cursor++
				if value < -1_000_000 || value > 1_000_000 { return -1 }
				if masks[row] & (1 << col) == 0 {
					if value != 0 { return -1 }
				} else {
					slots[row][col] = used
					sparse[used] = f64(value) / 1000.0
					used++
				}
			}
		}
		for block in 0 .. count {
			start := boundary[block]
			end := boundary[block + 1]
			for col in start .. end {
				pivot := sparse[slots[col][col]]
				if math.is_nan(pivot) || math.is_inf(pivot) || pivot <= 0 { return -1 }
				sparse[slots[col][col]] = math.sqrt(pivot)
				for row in col + 1 .. end { sparse[slots[row][col]] /= sparse[slots[col][col]] }
				for row in col + 1 .. end {
					for target in col + 1 .. row + 1 {
						sparse[slots[row][target]] -= sparse[slots[row][col]] * sparse[slots[target][col]]
					}
				}
			}
			for row in end .. n {
				if masks[row] & (1 << start) == 0 { continue }
				for col in start .. end {
					mut value := sparse[slots[row][col]]
					for k in start .. col { value -= sparse[slots[row][k]] * sparse[slots[col][k]] }
					sparse[slots[row][col]] = value / sparse[slots[col][col]]
				}
			}
			for row in end .. n {
				if masks[row] & (1 << start) == 0 { continue }
				for target in end .. row + 1 {
					if masks[target] & (1 << start) == 0 { continue }
					for k in start .. end {
						sparse[slots[row][target]] -= sparse[slots[row][k]] * sparse[slots[target][k]]
					}
				}
			}
		}
		required := triangle * 8
		if output == nil || capacity < usize(required) { return -2 }
		mut offset := 0
		for row in 0 .. n {
			for col in 0 .. row + 1 {
				mut value := 0.0
				if slots[row][col] >= 0 { value = sparse[slots[row][col]] }
				mut bits := math.bits_from_f64(value)
				for _ in 0 .. 8 {
					output[offset] = u8(bits & 255)
					bits >>= 8
					offset++
				}
			}
		}
		return i64(required)
	}
}
