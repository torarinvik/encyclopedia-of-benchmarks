module boundary_fill

const max_side = 32
const max_cells = max_side * max_side
const max_input_length = 6 + max_cells

fn put_i64(mut output &u8, index int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[index * 8 + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'boundary_fill']
pub fn boundary_fill(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > max_input_length { return -1 }
		width_value := input[0]; height_value := input[1]
		start_x_value := input[2]; start_y_value := input[3]
		new_color := input[4]; boundary_color := input[5]
		if width_value < 1 || width_value > max_side || height_value < 1 || height_value > max_side { return -1 }
		if new_color < -2147483648 || new_color > 2147483647 || boundary_color < -2147483648 || boundary_color > 2147483647 { return -1 }
		width := int(width_value); height := int(height_value)
		if length != usize(6 + width * height) || start_x_value < 0 || start_x_value >= width_value || start_y_value < 0 || start_y_value >= height_value { return -1 }
		cells := width * height
		mut image := []i64{len: max_cells}
		for index in 0 .. cells {
			image[index] = input[6 + index]
			if image[index] < -2147483648 || image[index] > 2147483647 { return -1 }
		}
		start := int(start_x_value) * height + int(start_y_value)
		if image[start] != new_color && image[start] != boundary_color {
			mut stack := []int{len: max_cells}
			mut top := 0
			image[start] = new_color
			stack[top] = start
			top++
			for top > 0 {
				top--
				index := stack[top]
				x := index / height; y := index % height
				for dx in -1 .. 2 {
					for dy in -1 .. 2 {
						if dx == 0 && dy == 0 { continue }
						next_x := x + dx; next_y := y + dy
						if next_x < 0 || next_x >= width || next_y < 0 || next_y >= height { continue }
						next := next_x * height + next_y
						if image[next] != new_color && image[next] != boundary_color {
							image[next] = new_color
							stack[top] = next
							top++
						}
					}
				}
			}
		}
		required := cells * 8
		if output == nil || capacity < usize(required) { return -2 }
		for index in 0 .. cells { put_i64(mut output, index, image[index]) }
		return i64(required)
	}
}
