package nonogram_line_domain_solver

import "core:c"

MAX_SIDE :: 8
MAX_LINES :: 16
Domains :: [MAX_LINES][4]u64

matches :: proc(mask: u32, length: int, clues: [^]i64, count: int) -> bool {
	found, run := 0, 0
	for bit := 0; bit < length; bit += 1 {
		if ((mask >> u32(bit)) & 1) != 0 { run += 1 }
		else if run != 0 {
			if found >= count || clues[found] != i64(run) do return false
			found += 1
			run = 0
		}
	}
	if run != 0 {
		if found >= count || clues[found] != i64(run) do return false
		found += 1
	}
	return found == count
}
has :: proc(domains: ^Domains, line: int, mask: u32) -> bool {
	return (domains[line][mask / 64] & (u64(1) << (mask % 64))) != 0
}
add :: proc(domains: ^Domains, line: int, mask: u32) {
	domains[line][mask / 64] |= u64(1) << (mask % 64)
}
domain_count :: proc(domains: ^Domains, line, length: int) -> int {
	total := 0
	for mask: u32 = 0; mask < (u32(1) << u32(length)); mask += 1 {
		if has(domains, line, mask) { total += 1 }
	}
	return total
}
filter :: proc(domains: ^Domains, line, length, pos: int, allow_zero, allow_one: bool) -> bool {
	changed := false
	for mask: u32 = 0; mask < (u32(1) << u32(length)); mask += 1 {
		if !has(domains, line, mask) do continue
		one := ((mask >> u32(pos)) & 1) != 0
		if (one && allow_one) || (!one && allow_zero) do continue
		domains[line][mask / 64] &= ~(u64(1) << (mask % 64))
		changed = true
	}
	return changed
}
support :: proc(domains: ^Domains, line, length, pos: int, zero, one: ^bool) -> bool {
	zero^ = false
	one^ = false
	for mask: u32 = 0; mask < (u32(1) << u32(length)); mask += 1 {
		if !has(domains, line, mask) do continue
		if ((mask >> u32(pos)) & 1) != 0 { one^ = true } else { zero^ = true }
	}
	return zero^ || one^
}
propagate :: proc(domains: ^Domains, height, width: int) -> bool {
	changed := true
	for changed {
		changed = false
		for row := 0; row < height; row += 1 {
			for col := 0; col < width; col += 1 {
				rz, ro, cz, co: bool
				if !support(domains, row, width, col, &rz, &ro) || !support(domains, height+col, height, row, &cz, &co) do return false
				if filter(domains, row, width, col, cz, co) { changed = true }
				if filter(domains, height+col, height, row, rz, ro) { changed = true }
				if domain_count(domains, row, width) == 0 || domain_count(domains, height+col, height) == 0 do return false
			}
		}
	}
	return true
}
search :: proc(domains: ^Domains, height, width: int) -> bool {
	if !propagate(domains, height, width) do return false
	branch := height
	for row := 0; row < height; row += 1 {
		if domain_count(domains, row, width) > 1 { branch = row; break }
	}
	if branch == height do return true
	for mask: u32 = 0; mask < (u32(1) << u32(width)); mask += 1 {
		if !has(domains, branch, mask) do continue
		trial := domains^
		for word := 0; word < 4; word += 1 { trial[branch][word] = 0 }
		add(&trial, branch, mask)
		if search(&trial, height, width) { domains^ = trial; return true }
	}
	return false
}
parse :: proc(input: [^]i64, length: c.size_t, height, width: ^int,
	clues: [^]i64, counts: [^]int) -> bool {
	if input == nil || length < 2 || input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 do return false
	height^ = int(input[0]); width^ = int(input[1])
	if length != c.size_t(2+5*height^+5*width^) do return false
	for i := 0; i < MAX_LINES*8; i += 1 { clues[i] = 0 }
	for i := 0; i < MAX_LINES; i += 1 { counts[i] = 0 }
	offset := 2
	for group := 0; group < 2; group += 1 {
		lines := height^
		line_length := width^
		if group == 1 { lines = width^; line_length = height^ }
		for line := 0; line < lines; line += 1 {
			index := line
			if group == 1 { index = height^ + line }
			raw_count := input[offset]; offset += 1
			if raw_count < 0 || raw_count > 4 do return false
			counts[index] = int(raw_count)
			needed := i64(0)
			if raw_count > 0 { needed = raw_count - 1 }
			for run := 0; run < 4; run += 1 {
				value := input[offset]; offset += 1
				if run < counts[index] {
					if value <= 0 || value > i64(line_length) do return false
					clues[index*8+run] = value
					needed += value
				} else if value != 0 { return false }
			}
			if needed > i64(line_length) do return false
		}
	}
	row_total, col_total := i64(0), i64(0)
	for row := 0; row < height^; row += 1 { for run := 0; run < counts[row]; run += 1 { row_total += clues[row*8+run] } }
	for col := 0; col < width^; col += 1 { for run := 0; run < counts[height^+col]; run += 1 { col_total += clues[(height^+col)*8+run] } }
	return row_total == col_total
}

@(export)
nonogram_line_domain_solver :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	height, width := 0, 0
	clues: [128]i64 = {}
	counts: [MAX_LINES]int = {}
	if !parse(input, length, &height, &width, &clues[0], &counts[0]) do return -1
	domains: Domains = {}
	for row := 0; row < height; row += 1 {
		for mask: u32 = 0; mask < (u32(1) << u32(width)); mask += 1 {
			if matches(mask, width, &clues[row*8], counts[row]) { add(&domains, row, mask) }
		}
		if domain_count(&domains, row, width) == 0 do return -1
	}
	for col := 0; col < width; col += 1 {
		line := height+col
		for mask: u32 = 0; mask < (u32(1) << u32(height)); mask += 1 {
			if matches(mask, height, &clues[line*8], counts[line]) { add(&domains, line, mask) }
		}
		if domain_count(&domains, line, height) == 0 do return -1
	}
	if !search(&domains, height, width) do return -1
	required := height*width
	if output == nil || output_capacity < c.size_t(required) do return -2
	for row := 0; row < height; row += 1 {
		mask: u32 = 0
		for mask < (u32(1) << u32(width)) && !has(&domains, row, mask) { mask += 1 }
		for col := 0; col < width; col += 1 { output[row*width+col] = u8((mask >> u32(col)) & 1) }
	}
	return i64(required)
}
