module jewels_and_stones

const max_jewels_length = 127
const max_stones_length = 4096
const max_packed_length = 4225

// Count stones whose ASCII byte appears in the unique-jewel set.
@[export: 'jewels_and_stones']
pub fn jewels_and_stones(input &i64, length usize) i64 {
	if length < 2 || length > max_packed_length { return -1 }
	if unsafe { input[0] < 0 || input[0] > max_jewels_length || input[1] < 0 || input[1] > max_stones_length } { return -1 }
	jewel_count := usize(unsafe { input[0] })
	stone_count := usize(unsafe { input[1] })
	if length != 2 + jewel_count + stone_count { return -1 }
	mut counts := [128]i64{init: 0}
	for index in 0 .. jewel_count {
		value := unsafe { input[2 + index] }
		if value < 1 || value > 127 { return -1 }
		if counts[usize(value)] != 0 { return -1 }
		counts[usize(value)] = 1
	}
	mut total := i64(0)
	stone_start := 2 + jewel_count
	for index in 0 .. stone_count {
		value := unsafe { input[stone_start + index] }
		if value < 1 || value > 127 { return -1 }
		total += counts[usize(value)]
	}
	return total
}
