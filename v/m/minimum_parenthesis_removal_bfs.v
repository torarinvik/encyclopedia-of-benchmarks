module minimum_parenthesis_removal_bfs

const max_text = 16
const max_parens = 8
const max_rows = 256
const max_output = 4354

fn bit_count(value0 int) int {
	mut value := value0
	mut count := 0
	for value != 0 { count += value & 1; value >>= 1 }
	return count
}

@[export: 'minimum_parenthesis_removal_bfs']
pub fn minimum_parenthesis_removal_bfs(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_text + 1 { return -1 }
		n_arg := input[0]
		if n_arg < 0 || n_arg > max_text || length != usize(n_arg + 1) { return -1 }
		n := int(n_arg)
		mut text := [max_text]u8{}
		mut positions := [max_parens]int{}
		mut p := 0
		for i in 0 .. n {
			value := input[i + 1]
			if value == 40 || value == 41 {
				if p == max_parens { return -1 }
				positions[p] = i
				p++
			} else if value < 97 || value > 122 { return -1 }
			text[i] = u8(value)
		}
		mut rows := [max_rows][max_text]u8{}
		mut sizes := [max_rows]u8{}
		mut count := 0
		states := 1 << p
		for deletions in 0 .. p + 1 {
			for mask in 0 .. states {
				if bit_count(mask) != deletions { continue }
				mut candidate := [max_text]u8{}
				mut used := 0
				mut ordinal := 0
				for i in 0 .. n {
					at_paren := ordinal < p && positions[ordinal] == i
					remove := at_paren && (mask & (1 << ordinal)) != 0
					if at_paren { ordinal++ }
					if !remove { candidate[used] = text[i]; used++ }
				}
				mut depth := 0
				mut valid := true
				for i in 0 .. used {
					if candidate[i] == `(` { depth++ }
					else if candidate[i] == `)` { depth--; if depth < 0 { valid = false; break } }
				}
				if !valid || depth != 0 { continue }
				mut duplicate := false
				for r in 0 .. count {
					if int(sizes[r]) != used { continue }
					mut same := true
					for j in 0 .. used { if rows[r][j] != candidate[j] { same = false } }
					if same { duplicate = true }
				}
				if !duplicate { rows[count] = candidate; sizes[count] = u8(used); count++ }
			}
			if count != 0 { break }
		}
		if count == 0 { sizes[0] = 0; count = 1 }
		for i in 1 .. count {
			key := rows[i]
			key_len := int(sizes[i])
			mut j := i
			for j > 0 {
				mut less := false
				common := key_len
				if int(sizes[j - 1]) < common { common = int(sizes[j - 1]) }
				for k in 0 .. common {
					if key[k] != rows[j - 1][k] { less = key[k] < rows[j - 1][k]; break }
				}
				if !less && key_len < int(sizes[j - 1]) { less = true }
				if !less { break }
				rows[j] = rows[j - 1]; sizes[j] = sizes[j - 1]; j--
			}
			rows[j] = key; sizes[j] = u8(key_len)
		}
		mut needed := 2
		for r in 0 .. count { needed += 1 + int(sizes[r]) }
		if needed > max_output { return -1 }
		if output == nil || capacity < usize(needed) { return -2 }
		output[0] = u8(count); output[1] = u8(count >> 8)
		mut pos := 2
		for r in 0 .. count {
			row_len := int(sizes[r]); output[pos] = u8(row_len); pos++
			for j in 0 .. row_len { output[pos] = rows[r][j]; pos++ }
		}
		return i64(pos)
	}
}
