module subset_combinations

// Emit fixed-size index combinations as little-endian subset masks.
@[export: 'subset_combinations']
pub fn subset_combinations(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > 13 { return -1 }
	if unsafe { input[0] } < 0 { return -1 }
	item_count := length - 1
	if item_count > 12 { return -1 }
	if unsafe { input[0] } > i64(item_count) { return 0 }
	choose := usize(unsafe { input[0] })
	mut count := usize(1)
	for index in 1 .. choose + 1 { count = count * (item_count - choose + index) / index }
	required := count * 2
	if output_capacity < required { return -2 }
	mut indices := [12]usize{}
	for index in 0 .. choose { indices[index] = index }
	for combination in 0 .. count {
		mut mask := usize(0)
		for index in 0 .. choose { mask |= usize(1) << indices[index] }
		unsafe {
			output[2 * combination] = u8(mask % 256)
			output[2 * combination + 1] = u8(mask / 256)
		}
		if combination + 1 == count { break }
		mut position := choose
		for position > 0 {
			position--
			if indices[position] < item_count - choose + position { break }
		}
		indices[position]++
		for index := position + 1; index < choose; index++ { indices[index] = indices[index - 1] + 1 }
	}
	return i64(count)
}
