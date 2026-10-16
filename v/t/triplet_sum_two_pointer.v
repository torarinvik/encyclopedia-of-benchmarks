fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

fn sift_down(mut values []i64, root_start int, end int) {
	mut root := root_start
	for root < end / 2 {
		mut child := root * 2 + 1
		if child + 1 < end && values[child] < values[child + 1] { child++ }
		if values[root] >= values[child] { break }
		values[root], values[child] = values[child], values[root]
		root = child
	}
}

fn heap_sort(mut values []i64) {
	mut start := values.len / 2
	for start > 0 {
		start--
		sift_down(mut values, start, values.len)
	}
	mut end := values.len
	for end > 1 {
		end--
		values[0], values[end] = values[end], values[0]
		sift_down(mut values, 0, end)
	}
}

@[export: 'triplet_sum_two_pointer']
pub fn triplet_sum_two_pointer(input &i64, length usize, mut output &u8,
		output_capacity usize) i64 {
	max_items := 1024
	if length < 1 || length > usize(max_items + 1) || isnil(input) { return -1 }
	target := unsafe { input[0] }
	if target < -3000000 || target > 3000000 { return -1 }
	item_count := int(length - 1)
	mut values := []i64{len: item_count, init: 0}
	for index in 0 .. item_count {
		value := unsafe { input[index + 1] }
		if value < -1000000 || value > 1000000 { return -1 }
		values[index] = value
	}
	if output_capacity < 24 || isnil(output) { return -2 }
	heap_sort(mut values)

	mut result := [3]i64{}
	if item_count >= 3 {
		for first in 0 .. item_count - 2 {
			mut left := first + 1
			mut right := item_count - 1
			for left < right {
				sum := values[first] + values[left] + values[right]
				if sum == target {
					result[0] = values[first]
					result[1] = values[left]
					result[2] = values[right]
					for index in 0 .. 3 { put_i64_le(mut output, index * 8, result[index]) }
					return 3
				}
				if sum < target { left++ } else { right-- }
			}
		}
	}
	for index in 0 .. 3 { put_i64_le(mut output, index * 8, result[index]) }
	return 3
}
