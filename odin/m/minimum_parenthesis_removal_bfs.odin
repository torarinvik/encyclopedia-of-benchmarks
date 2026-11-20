package minimum_parenthesis_removal_bfs

import "core:c"

Max_Text :: 16
Max_Parens :: 8
Max_Rows :: 256
Max_Output :: 4354

bit_count :: proc "contextless" (x0: u32) -> int {
	x := x0
	n := 0
	for x != 0 { n += int(x & 1); x >>= 1 }
	return n
}
balanced :: proc "contextless" (text: [^]u8, n: int) -> bool {
	depth := 0
	for i := 0; i < n; i += 1 {
		if text[i] == '(' { depth += 1 }
		else if text[i] == ')' { depth -= 1; if depth < 0 { return false } }
	}
	return depth == 0
}
@(export)
minimum_parenthesis_removal_bfs :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > Max_Text + 1 do return -1
	n64 := input[0]
	if n64 < 0 || n64 > Max_Text || length != c.size_t(n64 + 1) do return -1
	n := int(n64)
	text: [Max_Text]u8 = {}
	positions: [Max_Parens]u8 = {}
	p := 0
	for i := 0; i < n; i += 1 {
		v := input[i + 1]
		if v == 40 || v == 41 {
			if p == Max_Parens do return -1
			positions[p] = u8(i); p += 1
		} else if v < 97 || v > 122 do return -1
		text[i] = u8(v)
	}
	rows: [Max_Rows * Max_Text]u8 = {}
	sizes: [Max_Rows]u8 = {}
	count := 0
	states := 1 << p
	for deletions := 0; deletions <= p; deletions += 1 {
		for mask := 0; mask < states; mask += 1 {
			if bit_count(u32(mask)) != deletions do continue
			candidate: [Max_Text]u8 = {}
			used := 0; ordinal := 0
			for i := 0; i < n; i += 1 {
				at_paren := ordinal < p && int(positions[ordinal]) == i
				remove := at_paren && (mask & (1 << ordinal)) != 0
				if at_paren { ordinal += 1 }
				if !remove { candidate[used] = text[i]; used += 1 }
			}
			if !balanced(&candidate[0], used) do continue
			duplicate := false
			for r := 0; r < count; r += 1 {
				if int(sizes[r]) != used do continue
				same := true
				for j := 0; j < used; j += 1 {
					if rows[r * Max_Text + j] != candidate[j] { same = false }
				}
				if same { duplicate = true }
			}
			if !duplicate {
				for j := 0; j < used; j += 1 { rows[count * Max_Text + j] = candidate[j] }
				sizes[count] = u8(used); count += 1
			}
		}
		if count != 0 { break }
	}
	if count == 0 { sizes[0] = 0; count = 1 }
	for i := 1; i < count; i += 1 {
		key: [Max_Text]u8 = {}
		key_len := int(sizes[i])
		for j := 0; j < key_len; j += 1 { key[j] = rows[i * Max_Text + j] }
		j := i
		for j > 0 {
			less := false
			common := key_len
			if int(sizes[j - 1]) < common { common = int(sizes[j - 1]) }
			for k := 0; k < common; k += 1 {
				a := key[k]; b := rows[(j - 1) * Max_Text + k]
				if a != b { less = a < b; break }
			}
			if !less && key_len < int(sizes[j - 1]) { less = true }
			if !less { break }
			for k := 0; k < int(sizes[j - 1]); k += 1 { rows[j * Max_Text + k] = rows[(j - 1) * Max_Text + k] }
			sizes[j] = sizes[j - 1]; j -= 1
		}
		for k := 0; k < key_len; k += 1 { rows[j * Max_Text + k] = key[k] }
		sizes[j] = u8(key_len)
	}
	needed := 2
	for r := 0; r < count; r += 1 { needed += 1 + int(sizes[r]) }
	if needed > Max_Output do return -1
	if output == nil || capacity < c.size_t(needed) do return -2
	output[0] = u8(count); output[1] = u8(count >> 8); pos := 2
	for r := 0; r < count; r += 1 {
		row_len := int(sizes[r]); output[pos] = u8(row_len); pos += 1
		for j := 0; j < row_len; j += 1 { output[pos] = rows[r * Max_Text + j]; pos += 1 }
	}
	return i64(pos)
}
