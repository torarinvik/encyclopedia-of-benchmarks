module blob_detection

const max_side = 128
const max_cells = max_side * max_side
const max_input_length = 3 + 3 * max_cells

fn is_target_color(red i64, green i64, blue i64, profile i64) bool {
	mut maximum := red
	if green > maximum { maximum = green }
	if blue > maximum { maximum = blue }
	mut minimum := red
	if green < minimum { minimum = green }
	if blue < minimum { minimum = blue }
	delta := maximum - minimum
	mut hue_minimum := i64(379)
	mut hue_maximum := i64(496)
	mut saturation_minimum := i64(436)
	if profile == 1 {
		hue_minimum = 398
		hue_maximum = 498
		saturation_minimum = 355
	}
	if maximum == 0 || delta == 0 || 1000 * delta < saturation_minimum * maximum { return false }
	mut hue_numerator := i64(0)
	if maximum == red {
		hue_numerator = (green - blue) % (6 * delta)
		if hue_numerator < 0 { hue_numerator += 6 * delta }
	} else if maximum == green {
		hue_numerator = 2 * delta + blue - red
	} else {
		hue_numerator = 4 * delta + red - green
	}
	return hue_minimum * 6 * delta <= 1000 * hue_numerator &&
		1000 * hue_numerator <= hue_maximum * 6 * delta
}

@[export: 'blob_detection']
pub fn blob_detection(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	unsafe {
		height_value, width_value := input[0], input[1]
		profile := input[2]
		if height_value < 1 || height_value > max_side || width_value < 1 || width_value > max_side {
			return -1
		}
		height, width := int(height_value), int(width_value)
		cells := height * width
		if (profile != 0 && profile != 1) || length != usize(3 + 3 * cells) { return -1 }
		for channel in 0 .. 3 * cells {
			if input[3 + channel] < 0 || input[3 + channel] > 255 { return -1 }
		}

		mut mask := [max_cells]bool{}
		mut eroded := [max_cells]bool{}
		mut opened := [max_cells]bool{}
		mut visited := [max_cells]bool{}
		mut queue := [max_cells]usize{}
		for index in 0 .. cells {
			mask[index] = is_target_color(input[3 + 3 * index], input[4 + 3 * index], input[5 + 3 * index], profile)
		}

		for row in 0 .. height {
			for column in 0 .. width {
				mut keep := true
				for dy in -3 .. 4 {
					for dx in -3 .. 4 {
						if dx * dx + dy * dy > 9 { continue }
						y, x := row + dy, column + dx
						if y >= 0 && y < height && x >= 0 && x < width && !mask[y * width + x] {
							keep = false
							break
						}
					}
					if !keep { break }
				}
				eroded[row * width + column] = keep
			}
		}

		for row in 0 .. height {
			for column in 0 .. width {
				mut set := false
				for dy in -3 .. 4 {
					for dx in -3 .. 4 {
						if dx * dx + dy * dy > 9 { continue }
						y, x := row + dy, column + dx
						if y >= 0 && y < height && x >= 0 && x < width && eroded[y * width + x] {
							set = true
							break
						}
					}
					if set { break }
				}
				opened[row * width + column] = set
			}
		}

		mut object_count := i64(0)
		for start in 0 .. cells {
			if !opened[start] || visited[start] { continue }
			mut head, mut tail, mut area := usize(0), usize(0), usize(0)
			visited[start] = true
			queue[tail] = usize(start)
			tail++
			for head < tail {
				index := int(queue[head])
				head++
				area++
				row, column := index / width, index % width
				for dy in -1 .. 2 {
					for dx in -1 .. 2 {
						if dx == 0 && dy == 0 { continue }
						y, x := row + dy, column + dx
						if y < 0 || y >= height || x < 0 || x >= width { continue }
						neighbor := y * width + x
						if opened[neighbor] && !visited[neighbor] {
							visited[neighbor] = true
							queue[tail] = usize(neighbor)
							tail++
						}
					}
				}
			}
			if area >= 200 && area <= 5000 {
				object_count++
				if object_count == 50 { return object_count }
			}
		}
		return object_count
	}
}
