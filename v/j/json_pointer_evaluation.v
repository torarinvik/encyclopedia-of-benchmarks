module json_pointer_evaluation

const max_nodes = 32
const max_pointer = 64
const record_words = 21

fn field(values &i64, base int, node int, offset int) i64 {
	unsafe { return values[base + node * record_words + offset] }
}

@[export: 'json_pointer_evaluation']
pub fn json_pointer_evaluation(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	unsafe {
		if values == nil { return -1 }
		n_value, root_value, pointer_value := values[0], values[1], values[2]
		if n_value < 1 || n_value > max_nodes || root_value < 0 || root_value >= n_value ||
			pointer_value < 0 || pointer_value > max_pointer { return -1 }
		n, root, pointer_length := int(n_value), int(root_value), int(pointer_value)
		base := 3 + pointer_length
		if length != usize(base + n * record_words) { return -1 }
		for i in 0 .. pointer_length {
			if values[3 + i] < 0 || values[3 + i] > 127 { return -1 }
		}
		if pointer_length != 0 && values[3] != 47 { return -1 }
		mut syntax_pos := 1
		for syntax_pos < pointer_length {
			if values[3 + syntax_pos] == 126 {
				syntax_pos++
				if syntax_pos >= pointer_length { return -1 }
				escaped := values[3 + syntax_pos]
				if escaped != 48 && escaped != 49 { return -1 }
			}
			syntax_pos++
		}

		for i in 0 .. n {
			kind, parent, key_length, array_index := field(values, base, i, 0), field(values, base, i, 1), field(values, base, i, 2), field(values, base, i, 19)
			if kind < 0 || kind > 2 || key_length < 0 || key_length > 16 { return -1 }
			if i == root {
				if parent != -1 || key_length != 0 || array_index != -1 { return -1 }
			} else {
				if parent < 0 || parent >= n_value || int(parent) == i { return -1 }
				parent_kind := field(values, base, int(parent), 0)
				if parent_kind < 0 || parent_kind > 1 { return -1 }
				if parent_kind == 0 {
					if array_index != -1 { return -1 }
				} else if key_length != 0 || array_index < 0 { return -1 }
			}
			for k in 0 .. 16 {
				ch := field(values, base, i, 3 + k)
				if k < int(key_length) {
					if ch < 0 || ch > 127 { return -1 }
				} else if ch != 0 { return -1 }
			}
			cursor, hops := i, 0
			for cursor != root && hops < n {
				next := field(values, base, cursor, 1)
				if next < 0 || next >= n_value { return -1 }
				cursor = int(next)
				hops++
			}
			if cursor != root { return -1 }
		}
		for parent in 0 .. n {
			if field(values, base, parent, 0) != 1 { continue }
			mut children := 0
			for child in 0 .. n {
				if field(values, base, child, 1) == i64(parent) { children++ }
			}
			for child in 0 .. n {
				if field(values, base, child, 1) != i64(parent) { continue }
				index := field(values, base, child, 19)
				if index < 0 || index >= i64(children) { return -1 }
				for prior in 0 .. child {
					if field(values, base, prior, 1) == i64(parent) && field(values, base, prior, 19) == index { return -1 }
				}
			}
		}

		mut current := root
		if pointer_length == 0 { return i64(current) }
		mut token := [64]i64{}
		mut token_length := 0
		mut pos := 1
		for pos <= pointer_length {
			if pos == pointer_length || values[3 + pos] == 47 {
				kind := field(values, base, current, 0)
				mut found, mut matches := n, 0
				if kind == 0 {
					for child in 0 .. n {
						if field(values, base, child, 1) != i64(current) || field(values, base, child, 2) != i64(token_length) { continue }
						mut k := 0
						for k < token_length && field(values, base, child, 3 + k) == token[k] { k++ }
						if k == token_length { found = child; matches++ }
					}
				} else if kind == 1 {
					if token_length == 0 || (token_length > 1 && token[0] == 48) { return -2 }
					mut index := i64(0)
					for k in 0 .. token_length {
						if token[k] < 48 || token[k] > 57 { return -2 }
						index = index * 10 + token[k] - 48
						if index > max_nodes { return -2 }
					}
					for child in 0 .. n {
						if field(values, base, child, 1) == i64(current) && field(values, base, child, 19) == index { found = child; matches++ }
					}
				} else { return -2 }
				if matches != 1 { return -2 }
				current, token_length = found, 0
				pos++
				continue
			}
			mut ch := values[3 + pos]
			if ch == 126 {
				pos++
				if pos >= pointer_length { return -1 }
				escaped := values[3 + pos]
				if escaped == 48 { ch = 126 } else if escaped == 49 { ch = 47 } else { return -1 }
			}
			token[token_length] = ch
			token_length++
			pos++
		}
		return i64(current)
	}
}
