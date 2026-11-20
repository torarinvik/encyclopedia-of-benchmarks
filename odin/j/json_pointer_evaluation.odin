package json_pointer_evaluation

import "core:c"

MAX_NODES :: 32
MAX_POINTER :: 64
RECORD_WORDS :: 21

field :: proc(values: [^]i64, base, node, offset: int) -> i64 {
	return values[base + node*RECORD_WORDS + offset]
}

@(export)
json_pointer_evaluation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 do return -1
	n_value, root_value, pointer_value := values[0], values[1], values[2]
	if n_value < 1 || n_value > MAX_NODES || root_value < 0 || root_value >= n_value ||
		pointer_value < 0 || pointer_value > MAX_POINTER do return -1
	n, root, pointer_length := int(n_value), int(root_value), int(pointer_value)
	base := 3 + pointer_length
	if int(length) != base + n*RECORD_WORDS do return -1
	for i in 0..<pointer_length {
		if values[3+i] < 0 || values[3+i] > 127 do return -1
	}
	if pointer_length != 0 && values[3] != '/' do return -1
	syntax_pos := 1
	for syntax_pos < pointer_length {
		if values[3+syntax_pos] == '~' {
			syntax_pos += 1
			if syntax_pos >= pointer_length do return -1
			escaped := values[3+syntax_pos]
			if escaped != '0' && escaped != '1' do return -1
		}
		syntax_pos += 1
	}

	for i in 0..<n {
		kind, parent, key_length, array_index := field(values, base, i, 0), field(values, base, i, 1), field(values, base, i, 2), field(values, base, i, 19)
		if kind < 0 || kind > 2 || key_length < 0 || key_length > 16 do return -1
		if i == root {
			if parent != -1 || key_length != 0 || array_index != -1 do return -1
		} else {
			if parent < 0 || parent >= n_value || int(parent) == i do return -1
			parent_kind := field(values, base, int(parent), 0)
			if parent_kind < 0 || parent_kind > 1 do return -1
			if parent_kind == 0 {
				if array_index != -1 do return -1
			} else if key_length != 0 || array_index < 0 do return -1
		}
		for k in 0..<16 {
			ch := field(values, base, i, 3+k)
			if k < int(key_length) {
				if ch < 0 || ch > 127 do return -1
			} else if ch != 0 do return -1
		}
		cursor, hops := i, 0
		for cursor != root && hops < n {
			next := field(values, base, cursor, 1)
			if next < 0 || next >= n_value do return -1
			cursor = int(next)
			hops += 1
		}
		if cursor != root do return -1
	}
	for parent in 0..<n {
		if field(values, base, parent, 0) != 1 do continue
		children := 0
		for child in 0..<n {
			if field(values, base, child, 1) == i64(parent) do children += 1
		}
		for child in 0..<n {
			if field(values, base, child, 1) != i64(parent) do continue
			index := field(values, base, child, 19)
			if index < 0 || index >= i64(children) do return -1
			for prior in 0..<child {
				if field(values, base, prior, 1) == i64(parent) && field(values, base, prior, 19) == index do return -1
			}
		}
	}

	current := root
	if pointer_length == 0 do return i64(current)
	token: [64]i64 = {}
	token_length, pos := 0, 1
	for pos <= pointer_length {
		if pos == pointer_length || values[3+pos] == '/' {
			kind := field(values, base, current, 0)
			found, matches := n, 0
			if kind == 0 {
				for child in 0..<n {
					if field(values, base, child, 1) != i64(current) || field(values, base, child, 2) != i64(token_length) do continue
					k := 0
					for k < token_length && field(values, base, child, 3+k) == token[k] do k += 1
					if k == token_length { found = child; matches += 1 }
				}
			} else if kind == 1 {
				if token_length == 0 || (token_length > 1 && token[0] == '0') do return -2
				index: i64 = 0
				for k in 0..<token_length {
					if token[k] < '0' || token[k] > '9' do return -2
					index = index*10 + token[k] - '0'
					if index > MAX_NODES do return -2
				}
				for child in 0..<n {
					if field(values, base, child, 1) == i64(current) && field(values, base, child, 19) == index { found = child; matches += 1 }
				}
			} else do return -2
			if matches != 1 do return -2
			current, token_length = found, 0
			pos += 1
			continue
		}
		ch := values[3+pos]
		if ch == '~' {
			pos += 1
			if pos >= pointer_length do return -1
			escaped := values[3+pos]
			if escaped == '0' do ch = '~'
			else if escaped == '1' do ch = '/'
			else do return -1
		}
		token[token_length] = ch
		token_length += 1
		pos += 1
	}
	return i64(current)
}
