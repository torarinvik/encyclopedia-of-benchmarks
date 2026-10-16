package blob_detection

import "core:c"

MAX_SIDE :: 128
MAX_CELLS :: MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH :: 3 + 3 * MAX_CELLS

is_target_color :: proc "contextless" (red, green, blue, profile: i64) -> bool {
	maximum := max(red, max(green, blue))
	minimum := min(red, min(green, blue))
	delta := maximum - minimum
	hue_minimum, hue_maximum, saturation_minimum := i64(379), i64(496), i64(436)
	if profile == 1 {
		hue_minimum, hue_maximum, saturation_minimum = 398, 498, 355
	}
	if maximum == 0 || delta == 0 || 1000 * delta < saturation_minimum * maximum do return false
	hue_numerator: i64
	if maximum == red {
		hue_numerator = (green - blue) % (6 * delta)
		if hue_numerator < 0 do hue_numerator += 6 * delta
	} else if maximum == green {
		hue_numerator = 2 * delta + blue - red
	} else {
		hue_numerator = 4 * delta + red - green
	}
	return hue_minimum * 6 * delta <= 1000 * hue_numerator &&
		1000 * hue_numerator <= hue_maximum * 6 * delta
}

@(export)
blob_detection :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	height_value, width_value := input[0], input[1]
	profile := input[2]
	if height_value < 1 || height_value > MAX_SIDE ||
		width_value < 1 || width_value > MAX_SIDE {
		return -1
	}
	height, width := c.size_t(height_value), c.size_t(width_value)
	cells := height * width
	if (profile != 0 && profile != 1) || length != 3 + 3 * cells do return -1
	for channel: c.size_t = 0; channel < 3 * cells; channel += 1 {
		if input[3 + channel] < 0 || input[3 + channel] > 255 do return -1
	}

	mask: [MAX_CELLS]bool
	eroded: [MAX_CELLS]bool
	opened: [MAX_CELLS]bool
	visited: [MAX_CELLS]bool
	queue: [MAX_CELLS]c.size_t
	for index: c.size_t = 0; index < cells; index += 1 {
		mask[index] = is_target_color(input[3 + 3 * index], input[4 + 3 * index], input[5 + 3 * index], profile)
		visited[index] = false
	}

	for row: c.size_t = 0; row < height; row += 1 {
		for column: c.size_t = 0; column < width; column += 1 {
			keep := true
			for dy := -3; dy <= 3 && keep; dy += 1 {
				for dx := -3; dx <= 3; dx += 1 {
					if dx * dx + dy * dy > 9 do continue
					y, x := i64(row) + i64(dy), i64(column) + i64(dx)
					if y >= 0 && y < height_value && x >= 0 && x < width_value &&
						!mask[c.size_t(y) * width + c.size_t(x)] {
						keep = false
						break
					}
				}
			}
			eroded[row * width + column] = keep
		}
	}

	for row: c.size_t = 0; row < height; row += 1 {
		for column: c.size_t = 0; column < width; column += 1 {
			set := false
			for dy := -3; dy <= 3 && !set; dy += 1 {
				for dx := -3; dx <= 3; dx += 1 {
					if dx * dx + dy * dy > 9 do continue
					y, x := i64(row) + i64(dy), i64(column) + i64(dx)
					if y >= 0 && y < height_value && x >= 0 && x < width_value &&
						eroded[c.size_t(y) * width + c.size_t(x)] {
						set = true
						break
					}
				}
			}
			opened[row * width + column] = set
		}
	}

	object_count: i64 = 0
	for start: c.size_t = 0; start < cells; start += 1 {
		if !opened[start] || visited[start] do continue
		head, tail, area: c.size_t = 0, 0, 0
		visited[start] = true
		queue[tail] = start
		tail += 1
		for head < tail {
			index := queue[head]
			head += 1
			area += 1
			row, column := i64(index / width), i64(index % width)
			for dy := -1; dy <= 1; dy += 1 {
				for dx := -1; dx <= 1; dx += 1 {
					if dx == 0 && dy == 0 do continue
					y, x := row + i64(dy), column + i64(dx)
					if y < 0 || y >= height_value || x < 0 || x >= width_value do continue
					neighbor := c.size_t(y) * width + c.size_t(x)
					if opened[neighbor] && !visited[neighbor] {
						visited[neighbor] = true
						queue[tail] = neighbor
						tail += 1
					}
				}
			}
		}
		if area >= 200 && area <= 5000 {
			object_count += 1
			if object_count == 50 do return object_count
		}
	}
	return object_count
}
