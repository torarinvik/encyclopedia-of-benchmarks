package mediabench_gsm_rpe_grid_selection

import "core:c"

INPUT_COUNT :: 40
MAX_INPUT_LENGTH :: c.size_t(41)
OUTPUT_BYTES :: 112

asr2 :: proc(value: i64) -> i64 {
	if value >= 0 do return value / 4
	return -((-value + 3) / 4)
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
mediabench_gsm_rpe_grid_selection :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	for i := 0; i < int(input_length); i += 1 {
		if input[i] < -32768 || input[i] > 32767 do return -1
	}
	if input_length != c.size_t(INPUT_COUNT) do return -1
	best_score: i64 = -1
	best_grid: i64 = 0
	for grid: i64 = 0; grid < 4; grid += 1 {
		sum: i64 = 0
		for i: i64 = 0; i < 13; i += 1 {
			scaled := asr2(input[grid + 3 * i])
			sum += scaled * scaled
		}
		score := 2 * sum
		if score > best_score { best_score = score; best_grid = grid }
	}
	staged: [14]i64
	staged[0] = best_grid
	for i: i64 = 0; i < 13; i += 1 { staged[1 + i] = input[best_grid + 3 * i] }
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2
	for i := 0; i < 14; i += 1 { store_i64_le(output, i * 8, staged[i]) }
	return OUTPUT_BYTES
}
