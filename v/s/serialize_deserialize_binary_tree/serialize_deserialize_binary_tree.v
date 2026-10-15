module serialize_deserialize_binary_tree

const max_input = 2200
const max_nodes = 127

@[export: 'serialize_deserialize_binary_tree']
pub fn serialize_deserialize_binary_tree(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length == 0 || length > usize(max_input) { return -1 }
	unsafe { for i in 0 .. int(length) { if values[i] < 0 || values[i] > 127 { return -1 } } }
	mut encoded := ''
	mut position := 0
	mut slots := 1
	mut nodes := 0
	for position < int(length) {
		if slots == 0 { return -1 }
		start := position
		for position < int(length) && unsafe { values[position] != 44 } { position++ }
		finish := position
		if start == finish { return -1 }
		is_null := unsafe { finish - start == 4 && values[start] == 110 && values[start + 1] == 117 && values[start + 2] == 108 && values[start + 3] == 108 }
		if encoded.len > 0 { encoded += ',' }
		if is_null {
			encoded += 'null'
		} else {
			mut first := start
			mut last := finish
			for first < last && unsafe { values[first] == 32 || (values[first] >= 9 && values[first] <= 13) } { first++ }
			for last > first && unsafe { values[last - 1] == 32 || (values[last - 1] >= 9 && values[last - 1] <= 13) } { last-- }
			if first == last { return -1 }
			mut negative := false
			unsafe {
				if values[first] == 45 || values[first] == 43 { negative = values[first] == 45; first++ }
			}
			if first == last { return -1 }
			limit := i64(2147483647)
			if negative { limit = 2147483648 }
			mut magnitude := i64(0)
			unsafe {
				for i in first .. last {
					if values[i] < 48 || values[i] > 57 { return -1 }
					digit := values[i] - 48
					if magnitude > (limit - digit) / 10 { return -1 }
					magnitude = magnitude * 10 + digit
				}
			}
			if negative { magnitude = -magnitude }
			encoded += magnitude.str()
			nodes++
			if nodes > max_nodes { return -1 }
		}
		slots--
		if !is_null { slots += 2 }
		if position < int(length) { position++; if position == int(length) { return -1 } }
	}
	if slots != 0 { return -1 }
	if unsafe { output == nil } || output_capacity < usize(encoded.len) { return -2 }
	unsafe { for i in 0 .. encoded.len { output[i] = encoded[i] } }
	return i64(encoded.len)
}
