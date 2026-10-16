module chaining

@[export: 'chaining']
pub fn chaining(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 260 { return -1 }
	unsafe {
		bucket_count_value := input[0]
		operation_count_value := input[1]
		if bucket_count_value < 1 || bucket_count_value > 127 || operation_count_value < 0 || operation_count_value > 128 { return -1 }
		operation_count := int(operation_count_value)
		if int(length) != 2 + 2 * operation_count { return -1 }

		mut heads := [127]i64{init: -1}
		mut keys := [128]i64{}
		mut next_nodes := [128]i64{init: -1}
		mut inserted := 0
		mut query_count := 0
		mut mask := i64(0)
		for operation_index in 0 .. operation_count {
			offset := 2 + 2 * operation_index
			operation := input[offset]
			key := input[offset + 1]
			if (operation != 0 && operation != 1) || key < 0 || key > 2147483647 { return -1 }
			bucket := int(key % bucket_count_value)
			if operation == 0 {
				if inserted >= 128 { return -1 }
				keys[inserted] = key
				next_nodes[inserted] = -1
				if heads[bucket] < 0 { heads[bucket] = i64(inserted) }
				else {
					mut node := heads[bucket]
					for node >= 0 && next_nodes[int(node)] >= 0 { node = next_nodes[int(node)] }
					next_nodes[int(node)] = i64(inserted)
				}
				inserted++
			} else {
				if query_count >= 63 { return -1 }
				mut node := heads[bucket]
				for node >= 0 && keys[int(node)] != key { node = next_nodes[int(node)] }
				if node >= 0 { mask += i64(1) << query_count }
				query_count++
			}
		}
		return mask
	}
}
