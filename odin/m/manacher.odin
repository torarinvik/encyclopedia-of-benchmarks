package manacher

import "core:c"

is_ascii_alphanumeric :: proc "contextless" (value: i64) -> bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

transformed_equal :: proc "contextless" (values: [^]i64, left, right: int) -> bool {
	if (left % 2) != (right % 2) do return false
	if (left % 2) == 0 do return true
	return values[left / 2] == values[right / 2]
}

// Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm.
@(export)
manacher :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > 1000 || values == nil do return -1
	n := int(length)
	for index := 0; index < n; index += 1 {
		if !is_ascii_alphanumeric(values[index]) do return -1
	}

	var radii: [2001]int
	transformed_length := 2 * n + 1
	center := 0
	right := 0
	best_center := 0
	best_radius := 0
	for index := 0; index < transformed_length; index += 1 {
		radius := 0
		if index < right {
			mirror := 2 * center - index
			remaining := right - index
			if radii[mirror] < remaining {
				radius = radii[mirror]
			} else {
				radius = remaining
			}
		}
		for radius < index && radius < transformed_length - 1 - index &&
			transformed_equal(values, index - radius - 1, index + radius + 1) {
			radius += 1
		}
		radii[index] = radius
		if index + radius > right {
			center = index
			right = index + radius
		}
		if radius > best_radius {
			best_center = index
			best_radius = radius
		}
	}

	best_start := (best_center - best_radius) / 2
	if c.size_t(best_radius) > output_capacity || output == nil do return -2
	for index := 0; index < best_radius; index += 1 {
		output[index] = u8(values[best_start + index])
	}
	return i64(best_radius)
}
