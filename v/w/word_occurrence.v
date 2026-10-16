module word_occurrence

const max_input = 1024
const max_entries = 512
fn word_occurrence_ws(c u8) bool { return (c >= 9 && c <= 13) || (c >= 28 && c <= 32) }
fn word_occurrence_put32(mut output &u8, mut pos int, value u32) {
	mut bits := value
	for _ in 0 .. 4 { unsafe { output[pos] = u8(bits & 255) }; pos++; bits >>= 8 }
}

@[export: 'word_occurrence']
pub fn word_occurrence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 1025 { return -1 }
	n_arg := unsafe { input[0] }
	if n_arg < 0 || n_arg > 1024 || length != usize(n_arg + 1) { return -1 }
	n := int(n_arg)
	mut text := [max_input]u8{}
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < 0 || value > 127 { return -1 }
		text[i] = u8(value)
	}
	mut starts := [max_entries]int{}
	mut lens := [max_entries]int{}
	mut counts := [max_entries]u32{}
	mut entries := 0
	mut i := 0
	for i < n {
		for i < n && word_occurrence_ws(text[i]) { i++ }
		if i == n { break }
		start := i
		for i < n && !word_occurrence_ws(text[i]) { i++ }
		token_len := i - start
		mut entry := 0
		for entry < entries {
			if lens[entry] == token_len {
				mut offset := 0
				for offset < token_len && text[starts[entry] + offset] == text[start + offset] { offset++ }
				if offset == token_len { break }
			}
			entry++
		}
		if entry == entries {
			if entries >= max_entries { return -1 }
			starts[entry] = start
			lens[entry] = token_len
			entries++
		}
		counts[entry]++
	}
	mut need := 4
	for j in 0 .. entries { need += 8 + lens[j] }
	if unsafe { output == nil } || capacity < usize(need) { return -2 }
	mut pos := 0
	word_occurrence_put32(mut output, mut pos, u32(entries))
	for j in 0 .. entries {
		word_occurrence_put32(mut output, mut pos, u32(lens[j]))
		for q in 0 .. lens[j] { unsafe { output[pos] = text[starts[j] + q] }; pos++ }
		word_occurrence_put32(mut output, mut pos, counts[j])
	}
	return i64(pos)
}
