module hofstadter_figure_figure_sequences

const max_terms = 64
const max_words = 129

fn write_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte] = u8((bits>>(byte*8))&255) } }
}

@[export: 'hofstadter_figure_figure_sequences']
pub fn hofstadter_figure_figure_sequences(input &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > 2 { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_terms || length != 1 { return -1 }
		n := int(n_value)
		mut figure := [max_terms]i64{}
		mut space := [max_terms]i64{}
		figure[0] = 1
		space[0] = 2
		mut candidate := i64(3)
		for i in 1 .. n {
			figure[i] = figure[i-1] + space[i-1]
			mut used := true
			for used {
				used = false
				for j in 0 .. (i + 1) { if figure[j] == candidate { used = true } }
				if used { candidate++ }
			}
			space[i] = candidate
			candidate++
		}
		word_count := 1+2*n
		output_bytes := word_count*8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		mut words := [max_words]i64{}
		words[0] = n_value
		for i in 0 .. n { words[1+i] = figure[i]; words[1+n+i] = space[i] }
		for i in 0 .. word_count { write_i64_le(output,i*8,words[i]) }
		return i64(output_bytes)
	}
}
