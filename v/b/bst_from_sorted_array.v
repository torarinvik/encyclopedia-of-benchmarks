fn bst_shape(start int, ending int, heap_index int) u64 {
	if start >= ending { return u64(0) }
	middle := start + (ending - start - 1) / 2
	return (u64(1) << u64(heap_index)) |
		bst_shape(start, middle, 2 * heap_index + 1) |
		bst_shape(middle + 1, ending, 2 * heap_index + 2)
}

@[export: 'bst_from_sorted_array']
pub fn bst_from_sorted_array(input &i64, length usize) i64 {
	unsafe {
		if length > 15 { return -1 }
		for index in usize(0) .. length {
			value := input[index]
			if value < -2147483648 || value > 2147483647 { return -1 }
			if index > 0 && input[index - 1] >= value { return -1 }
		}
		return i64(bst_shape(0, int(length), 0))
	}
}
