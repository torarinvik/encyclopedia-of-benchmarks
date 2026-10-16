package brightness

import "core:c"

@(export)
brightness :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	for channel := 0; channel < 3; channel += 1 {
		if input[channel] < 0 || input[channel] > 255 do return -1
	}

	training := [44]i64{
		2, 99, 255, 1, 37, 44, 58, 0, 139, 169, 229, 1,
		14, 255, 10, 1, 2, 28, 1, 0, 20, 33, 20, 0,
		252, 227, 65, 1, 71, 65, 24, 0, 168, 80, 80, 1,
		119, 35, 90, 0, 186, 13, 126, 1,
	}
	best_distance: i64 = 195076
	best_label: i64 = -1
	for sample := 0; sample < 11; sample += 1 {
		red_delta := input[0] - training[sample * 4]
		green_delta := input[1] - training[sample * 4 + 1]
		blue_delta := input[2] - training[sample * 4 + 2]
		distance := red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta
		if distance < best_distance {
			best_distance = distance
			best_label = training[sample * 4 + 3]
		}
	}
	return best_label
}
