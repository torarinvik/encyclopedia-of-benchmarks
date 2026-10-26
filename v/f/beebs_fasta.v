module beebs_fasta

const max_count = i64(1000)
const max_state = i64(139967)
const width = 60
const alu = 'GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGGGAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGACCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAATACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCAGCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGGAGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA'
const iub_weights = [15]f32{0.27,0.12,0.12,0.27,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02,0.02}
const iub_symbols = [15]u8{'a','c','g','t','B','D','H','K','M','N','R','S','V','W','Y'}
const human_weights = [4]f32{0.3029549426680,0.1979883004921,0.1975473066391,0.3015094502008}
const human_symbols = [4]u8{'a','c','g','t'}

fn wrapped_lines(count int) int { return (count + width - 1) / width }

fn fasta_output_length(count int) int {
	return 77 + 10 * count + wrapped_lines(2 * count) + wrapped_lines(3 * count) + wrapped_lines(5 * count)
}

fn accumulate_probabilities(mut weights []f32) {
	mut cumulative := f32(0)
	for i in 0 .. weights.len {
		cumulative += weights[i]
		weights[i] = cumulative
	}
}

fn next_weighted_base(mut state u32, weights []f32, symbols []u8) u8 {
	state = (state * u32(3877) + u32(29573)) % u32(139968)
	random_value := f32(1) * f32(state) / f32(139968)
	for i in 0 .. weights.len {
		if weights[i] >= random_value { return symbols[i] }
	}
	return symbols[symbols.len - 1]
}

fn write_repeat(mut output &u8, mut offset int, count int) int {
	for i in 0 .. count {
		unsafe { output[offset] = alu[i % alu.len] }
		offset++
		if (i + 1) % width == 0 || i + 1 == count {
			unsafe { output[offset] = 10 }
			offset++
		}
	}
	return offset
}

fn write_weighted(mut output &u8, mut offset int, count int, mut state u32,
				  weights []f32, symbols []u8) int {
	for i in 0 .. count {
		unsafe { output[offset] = next_weighted_base(mut state, weights, symbols) }
		offset++
		if (i + 1) % width == 0 || i + 1 == count {
			unsafe { output[offset] = 10 }
			offset++
		}
	}
	return offset
}

@[export: 'beebs_fasta']
pub fn beebs_fasta(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length != 2 { return -1 }
	count_value := unsafe { values[0] }
	seed_value := unsafe { values[1] }
	if count_value < 1 || count_value > max_count || seed_value < 0 || seed_value > max_state { return -1 }
	count := int(count_value)
	needed := fasta_output_length(count)
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }
	mut iub_thresholds := iub_weights
	mut human_thresholds := human_weights
	accumulate_probabilities(mut iub_thresholds[..])
	accumulate_probabilities(mut human_thresholds[..])
	header_one := '>ONE Homo sapiens alu\n'
	header_two := '>TWO IUB ambiguity codes\n'
	header_three := '>THREE Homo sapiens frequency\n'
	mut offset := 0
	for i in 0 .. header_one.len { unsafe { output[offset] = header_one[i] }; offset++ }
	offset = write_repeat(mut output, offset, 2 * count)
	for i in 0 .. header_two.len { unsafe { output[offset] = header_two[i] }; offset++ }
	mut state := u32(seed_value)
	offset = write_weighted(mut output, offset, 3 * count, mut state, iub_thresholds[..], iub_symbols[..])
	for i in 0 .. header_three.len { unsafe { output[offset] = header_three[i] }; offset++ }
	offset = write_weighted(mut output, offset, 5 * count, mut state, human_thresholds[..], human_symbols[..])
	return i64(offset)
}
