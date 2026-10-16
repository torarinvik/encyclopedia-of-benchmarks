module generate_rule_30_grid

const max_width = 64
const max_generations = 64

@[export: 'generate_rule_30_grid']
pub fn generate_rule_30_grid(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		width_value := input[0]
		generations_value := input[1]
		if width_value < 1 || width_value > max_width || generations_value < 1 || generations_value > max_generations { return -1 }
		width := int(width_value)
		generations := int(generations_value)
		output_count := width * generations
		if output_capacity < usize(output_count) || output == nil { return -2 }
		mut current := [64]i64{}
		mut next := [64]i64{}
		current[width / 2] = 1
		for column in 0 .. width { output[column] = u8(current[column]) }
		for generation in 1 .. generations {
			for column in 0 .. width {
				left := if column > 0 { current[column - 1] } else { i64(0) }
				right := if column + 1 < width { current[column + 1] } else { i64(0) }
				pattern := u32(left * 4 + current[column] * 2 + right)
				next[column] = i64((u32(30) >> pattern) & 1)
			}
			for column in 0 .. width {
				current[column] = next[column]
				output[generation * width + column] = u8(next[column])
			}
		}
		return i64(output_count)
	}
}
