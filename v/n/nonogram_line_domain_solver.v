module nonogram_line_domain_solver

type Domains = [16][4]u64

fn nn_matches(mask u32, length int, clues &i64, count int) bool {
	mut found := 0
	mut run := 0
	for bit in 0 .. length {
		if ((mask >> u32(bit)) & 1) != 0 { run++ }
		else if run != 0 {
			if found >= count || unsafe { clues[found] } != i64(run) { return false }
			found++
			run = 0
		}
	}
	if run != 0 {
		if found >= count || unsafe { clues[found] } != i64(run) { return false }
		found++
	}
	return found == count
}
fn nn_has(domains &Domains, line int, mask u32) bool {
	return (domains[line][int(mask / 64)] & (u64(1) << (mask % 64))) != 0
}
fn nn_add(mut domains Domains, line int, mask u32) {
	domains[line][int(mask / 64)] |= u64(1) << (mask % 64)
}
fn nn_count(domains &Domains, line int, length int) int {
	mut total := 0
	for mask in u32(0) .. (u32(1) << u32(length)) { if nn_has(domains, line, mask) { total++ } }
	return total
}
fn nn_filter(mut domains Domains, line int, length int, pos int, allow_zero bool, allow_one bool) bool {
	mut changed := false
	for mask in u32(0) .. (u32(1) << u32(length)) {
		if !nn_has(domains, line, mask) { continue }
		one := ((mask >> u32(pos)) & 1) != 0
		if (one && allow_one) || (!one && allow_zero) { continue }
		domains[line][int(mask / 64)] &= ~(u64(1) << (mask % 64))
		changed = true
	}
	return changed
}
fn nn_support(domains &Domains, line int, length int, pos int, mut zero bool, mut one bool) bool {
	zero = false
	one = false
	for mask in u32(0) .. (u32(1) << u32(length)) {
		if !nn_has(domains, line, mask) { continue }
		if ((mask >> u32(pos)) & 1) != 0 { one = true } else { zero = true }
	}
	return zero || one
}
fn nn_propagate(mut domains Domains, height int, width int) bool {
	mut changed := true
	for changed {
		changed = false
		for row in 0 .. height {
			for col in 0 .. width {
				mut rz, ro, cz, co := false, false, false, false
				if !nn_support(domains, row, width, col, mut rz, mut ro) || !nn_support(domains, height + col, height, row, mut cz, mut co) { return false }
				if nn_filter(mut domains, row, width, col, cz, co) { changed = true }
				if nn_filter(mut domains, height + col, height, row, rz, ro) { changed = true }
				if nn_count(domains, row, width) == 0 || nn_count(domains, height + col, height) == 0 { return false }
			}
		}
	}
	return true
}
fn nn_search(mut domains Domains, height int, width int) bool {
	if !nn_propagate(mut domains, height, width) { return false }
	mut branch := height
	for row in 0 .. height { if nn_count(domains, row, width) > 1 { branch = row; break } }
	if branch == height { return true }
	for mask in u32(0) .. (u32(1) << u32(width)) {
		if !nn_has(domains, branch, mask) { continue }
		mut trial := domains
		for word in 0 .. 4 { trial[branch][word] = 0 }
		nn_add(mut trial, branch, mask)
		if nn_search(mut trial, height, width) { domains = trial; return true }
	}
	return false
}

@[export: 'nonogram_line_domain_solver']
pub fn nonogram_line_domain_solver(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 82 { return -1 }
	unsafe {
		height_value := input[0]
		width_value := input[1]
		if height_value < 1 || height_value > 8 || width_value < 1 || width_value > 8 { return -1 }
		height, width := int(height_value), int(width_value)
		if length != usize(2 + 5 * height + 5 * width) { return -1 }
		mut clues := [128]i64{}
		mut counts := [16]int{}
		offset := 2
		for group in 0 .. 2 {
			lines := if group == 0 { height } else { width }
			line_length := if group == 0 { width } else { height }
			for line in 0 .. lines {
				index := if group == 0 { line } else { height + line }
				raw_count := input[offset]; offset++
				if raw_count < 0 || raw_count > 4 { return -1 }
				counts[index] = int(raw_count)
				mut needed := if raw_count == 0 { i64(0) } else { raw_count - 1 }
				for run in 0 .. 4 {
					value := input[offset]; offset++
					if run < counts[index] {
						if value <= 0 || value > i64(line_length) { return -1 }
						clues[index * 8 + run] = value
						needed += value
					} else if value != 0 { return -1 }
				}
				if needed > i64(line_length) { return -1 }
			}
		}
		mut row_total, col_total := i64(0), i64(0)
		for row in 0 .. height { for run in 0 .. counts[row] { row_total += clues[row * 8 + run] } }
		for col in 0 .. width { for run in 0 .. counts[height + col] { col_total += clues[(height + col) * 8 + run] } }
		if row_total != col_total { return -1 }
		mut domains := Domains{}
		for row in 0 .. height {
			for mask in u32(0) .. (u32(1) << u32(width)) {
				if nn_matches(mask, width, unsafe { &clues[row * 8] }, counts[row]) { nn_add(mut domains, row, mask) }
			}
			if nn_count(domains, row, width) == 0 { return -1 }
		}
		for col in 0 .. width {
			line := height + col
			for mask in u32(0) .. (u32(1) << u32(height)) {
				if nn_matches(mask, height, unsafe { &clues[line * 8] }, counts[line]) { nn_add(mut domains, line, mask) }
			}
			if nn_count(domains, line, height) == 0 { return -1 }
		}
		if !nn_search(mut domains, height, width) { return -1 }
		required := height * width
		if output == nil || output_capacity < usize(required) { return -2 }
		for row in 0 .. height {
			mut mask := u32(0)
			for mask < (u32(1) << u32(width)) && !nn_has(domains, row, mask) { mask++ }
			for col in 0 .. width { output[row * width + col] = u8((mask >> u32(col)) & 1) }
		}
		return i64(required)
	}
}
