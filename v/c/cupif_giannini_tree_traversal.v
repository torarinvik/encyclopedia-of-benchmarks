module cupif_giannini_tree_traversal

@[export: 'cupif_giannini_tree_traversal']
pub fn cupif_giannini_tree_traversal(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 3 { return -1 }
	if length != 2 { return -1 }

	height_value := unsafe { input[0] }
	key_value := unsafe { input[1] }
	if height_value < 0 || height_value > 6 { return -1 }
	height := int(height_value)
	leaf_count := usize(1) << height
	if key_value < 0 || key_value >= i64(leaf_count) { return -1 }
	if unsafe { output == nil } || capacity < leaf_count { return -2 }

	for count in 0 .. leaf_count {
		path := u64(count) ^ u64(key_value)
		mut leaf_code := u8(0)
		for depth in 0 .. height {
			if ((path >> u32(depth)) & 1) != 0 {
				leaf_code |= u8(1) << u32(depth)
			}
		}
		unsafe { output[count] = leaf_code }
	}
	return i64(leaf_count)
}
