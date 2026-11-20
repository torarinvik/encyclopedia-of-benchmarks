package hofstadter_figure_figure_sequences

import "core:c"

MAX_TERMS :: 64
MAX_WORDS :: 129

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits>>(byte*8))&255) }
}

@(export)
hofstadter_figure_figure_sequences :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > 2 do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_TERMS || length != 1 do return -1
	n := int(n_value)
	var figure: [MAX_TERMS]i64
	var space: [MAX_TERMS]i64
	figure[0] = 1
	space[0] = 2
	candidate: i64 = 3
	for i := 1; i < n; i += 1 {
		figure[i] = figure[i-1] + space[i-1]
		used := true
		for used {
			used = false
			for j := 0; j <= i; j += 1 { if figure[j] == candidate { used = true } }
			if used { candidate += 1 }
		}
		space[i] = candidate
		candidate += 1
	}
	word_count := 1 + 2*n
	output_bytes := word_count*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	var words: [MAX_WORDS]i64
	words[0] = n_value
	for i := 0; i < n; i += 1 { words[1+i] = figure[i]; words[1+n+i] = space[i] }
	for i := 0; i < word_count; i += 1 { write_i64_le(output,i*8,words[i]) }
	return i64(output_bytes)
}
