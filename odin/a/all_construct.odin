package all_construct

import "core:c"

MAX_TARGET :: 6
MAX_WORDS :: 4
MAX_WAYS :: 4096

@(export)
all_construct :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	if input[0] < 0 || input[0] > MAX_TARGET do return -1
	n := int(input[0])
	for i := 0; i < n; i += 1 { if input[i + 1] < 97 || input[i + 1] > 122 do return -1 }
	wc_slot := n + 1
	if c.size_t(wc_slot) >= length || input[wc_slot] < 0 || input[wc_slot] > MAX_WORDS do return -1
	words := int(input[wc_slot])
	starts: [MAX_WORDS]int
	word_lengths: [MAX_WORDS]int
	cursor := wc_slot + 1
	for w := 0; w < words; w += 1 {
		if c.size_t(cursor) >= length || input[cursor] < 1 || input[cursor] > MAX_TARGET do return -1
		wl := int(input[cursor]); cursor += 1
		if c.size_t(cursor + wl) > length do return -1
		starts[w] = cursor; word_lengths[w] = wl
		for j := 0; j < wl; j += 1 { if input[cursor + j] < 97 || input[cursor + j] > 122 do return -1 }
		cursor += wl
	}
	if c.size_t(cursor) != length do return -1
	paths: [((MAX_TARGET + 1) * MAX_WAYS * MAX_TARGET)]u8
	path_lengths: [((MAX_TARGET + 1) * MAX_WAYS)]u8
	counts: [MAX_TARGET + 1]int
	counts[0] = 1
	for pos := 0; pos < n; pos += 1 {
		for w := 0; w < words; w += 1 {
			wl := word_lengths[w]
			if wl > n - pos do continue
			matched := true
			for j := 0; j < wl; j += 1 { if input[pos + 1 + j] != input[starts[w] + j] { matched = false } }
			if !matched do continue
			ending := pos + wl
			for row := 0; row < counts[pos]; row += 1 {
				dest := counts[ending]
				if dest >= MAX_WAYS do return -1
				counts[ending] += 1
				src_base := (pos * MAX_WAYS + row) * MAX_TARGET
				dst_base := (ending * MAX_WAYS + dest) * MAX_TARGET
				plen := int(path_lengths[pos * MAX_WAYS + row])
				for k := 0; k < plen; k += 1 { paths[dst_base + k] = paths[src_base + k] }
				paths[dst_base + plen] = u8(w)
				path_lengths[ending * MAX_WAYS + dest] = u8(plen + 1)
			}
		}
	}
	required := 0
	for row := 0; row < counts[n]; row += 1 {
		plen := int(path_lengths[n * MAX_WAYS + row]); required += 1
		for k := 0; k < plen; k += 1 { w := int(paths[(n * MAX_WAYS + row) * MAX_TARGET + k]); required += 1 + word_lengths[w] }
	}
	if c.size_t(required) > output_capacity || (required > 0 && output == nil) do return -2
	if counts[n] == 0 do return 0
	written := 0
	for row := 0; row < counts[n]; row += 1 {
		base := (n * MAX_WAYS + row) * MAX_TARGET
		plen := int(path_lengths[n * MAX_WAYS + row])
		output[written] = u8(plen); written += 1
		for k := 0; k < plen; k += 1 {
			w := int(paths[base + k]); wl := word_lengths[w]
			output[written] = u8(wl); written += 1
			for j := 0; j < wl; j += 1 { output[written] = u8(input[starts[w] + j]); written += 1 }
		}
	}
	return i64(counts[n])
}
