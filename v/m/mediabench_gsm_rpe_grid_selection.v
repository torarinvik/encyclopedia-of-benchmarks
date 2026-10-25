module mediabench_gsm_rpe_grid_selection

const input_count = 40
const max_input_length = 41
const output_bytes = 112

fn asr2(value i64) i64 {
	return if value >= 0 { value / 4 } else { -((-value + 3) / 4) }
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'mediabench_gsm_rpe_grid_selection']
pub fn mediabench_gsm_rpe_grid_selection(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length == 0 || input_length > max_input_length { return -1 }
		for i in 0 .. input_length { if input[i] < -32768 || input[i] > 32767 { return -1 } }
		if input_length != input_count { return -1 }
		mut best_score := i64(-1)
	mut best_grid := i64(0)
		for grid in i64(0) .. i64(4) {
			mut sum := i64(0)
			for i in i64(0) .. i64(13) {
				scaled := asr2(input[grid + 3 * i])
				sum += scaled * scaled
			}
			score := 2 * sum
			if score > best_score { best_score = score; best_grid = grid }
		}
		mut staged := [14]i64{}
		staged[0] = best_grid
		for i in i64(0) .. i64(13) { staged[1 + i] = input[best_grid + 3 * i] }
		if output == nil || output_capacity < output_bytes { return -2 }
		for i in 0 .. 14 { store_i64_le(mut output, i * 8, staged[i]) }
		return output_bytes
	}
}
