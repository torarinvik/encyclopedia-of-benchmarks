module merge_sort_linked_list

fn merge_nodes(values &i32, mut links &i32, left int, right int) int {
	if left < 0 { return right }
	if right < 0 { return left }
	left_value := unsafe { values[left] }
	right_value := unsafe { values[right] }
	if left_value <= right_value {
		left_next := unsafe { links[left] }
		merged := merge_nodes(values, mut links, left_next, right)
		unsafe { links[left] = merged }
		return left
	}
	right_next := unsafe { links[right] }
	merged := merge_nodes(values, mut links, left, right_next)
	unsafe { links[right] = merged }
	return right
}

fn merge_sort_nodes(values &i32, mut links &i32, head int) int {
	if head < 0 || unsafe { links[head] < 0 } { return head }
	mut slow := head
	mut fast := unsafe { links[head] }
	for fast >= 0 {
		fast_next := unsafe { links[fast] }
		if fast_next < 0 { break }
		slow = unsafe { links[slow] }
		fast = unsafe { links[fast_next] }
	}
	right_head := unsafe { links[slow] }
	unsafe { links[slow] = -1 }
	left := merge_sort_nodes(values, mut links, head)
	right := merge_sort_nodes(values, mut links, right_head)
	return merge_nodes(values, mut links, left, right)
}

@[export: 'merge_sort_linked_list']
pub fn merge_sort_linked_list(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 1 || length > 129 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > 128 { return -1 }
	count := int(count_value)
	if length != usize(1 + count) { return -1 }
	mut values := [128]i32{}
	mut links := [128]i32{}
	for i in 0 .. count {
		value := unsafe { input[1 + i] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[i] = i32(value)
		for j in 0 .. i { if values[j] == values[i] { return -1 } }
		links[i] = -1
		if i + 1 < count { links[i] = i + 1 }
	}
	mut head := -1
	if count > 0 { head = merge_sort_nodes(&values[0], mut links[0], 0) }
	required := 4 * count
	if output == nil || output_capacity < usize(required) { return -2 }
	mut node := head
	for i in 0 .. count {
		bits := u32(unsafe { values[node] })
		for byte in 0 .. 4 { unsafe { output[4 * i + byte] = u8((bits >> (8 * byte)) & 255) } }
		node = unsafe { links[node] }
	}
	return i64(required)
}
