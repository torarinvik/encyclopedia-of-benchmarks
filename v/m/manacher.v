module manacher

fn is_ascii_alphanumeric(value i64) bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

fn transformed_equal(values &i64, left usize, right usize) bool {
	if (left % 2) != (right % 2) { return false }
	if (left % 2) == 0 { return true }
	return unsafe { values[left / 2] == values[right / 2] }
}

// Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm.
@[export: 'manacher']
pub fn manacher(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > 1000 { return -1 }
	for index in 0 .. length {
		if !is_ascii_alphanumeric(unsafe { values[index] }) { return -1 }
	}

	mut radii := [2001]usize{}
	transformed_length := 2 * length + 1
	mut center := usize(0)
	mut right := usize(0)
	mut best_center := usize(0)
	mut best_radius := usize(0)
	for index in 0 .. transformed_length {
		mut radius := usize(0)
		if index < right {
			mirror := 2 * center - index
			remaining := right - index
			radius = if radii[mirror] < remaining { radii[mirror] } else { remaining }
		}
		for radius < index && radius < transformed_length - 1 - index &&
			transformed_equal(values, index - radius - 1, index + radius + 1) {
			radius++
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
	if best_radius > output_capacity { return -2 }
	for index in 0 .. best_radius {
		unsafe { output[index] = u8(values[best_start + index]) }
	}
	return i64(best_radius)
}
