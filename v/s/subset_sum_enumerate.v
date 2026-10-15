module subset_sum_enumerate

// Emit the index masks of all signed subsets matching the target.
@[export: 'subset_sum_enumerate']
pub fn subset_sum_enumerate(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > 9 { return -1 }
	target := unsafe { input[0] }
	if target < -512 || target > 512 { return -1 }
	items := length - 1
	for index in 0 .. items {
		value := unsafe { input[index + 1] }
		if value < -64 || value > 64 { return -1 }
	}
	mut masks := [256]u8{}
	mut count := usize(0)
	limit := usize(1) << items
	for mask in 0 .. limit {
		mut sum := i64(0)
		mut bit := usize(1)
		for index in 0 .. items {
			if mask / bit % 2 == 1 { sum += unsafe { input[index + 1] } }
			bit *= 2
		}
		if sum == target { masks[count] = u8(mask); count++ }
	}
	if output_capacity < count { return -2 }
	for index in 0 .. count { unsafe { output[index] = masks[index] } }
	return i64(count)
}
