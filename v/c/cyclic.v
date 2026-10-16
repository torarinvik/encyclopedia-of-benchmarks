module cyclic

fn rotate_list(next &i64, previous &i64, mut head &i64, size i64, places i64) {
	if size == 0 { return }
	mut steps := places % size
	if steps < 0 { steps += size }
	unsafe {
		if steps > size / 2 {
			steps = size - steps
			for _ in 0 .. int(steps) { head = previous[int(head)] }
		} else {
			for _ in 0 .. int(steps) { head = next[int(head)] }
		}
	}
}

fn delete_head(mut values &i64, mut next &i64, mut previous &i64, mut head &i64, mut size &i64) bool {
	if size == 0 { return false }
	unsafe {
		current := int(head)
		if size == 1 { head = -1 }
		else {
			successor, predecessor := next[current], previous[current]
			next[int(predecessor)] = successor
			previous[int(successor)] = predecessor
			head = successor
		}
		values[current] = 0
		size--
	}
	return true
}

fn add_record(mut records &i64, mut field_count &int, value i64) {
	unsafe { records[field_count] = value }
	field_count++
}

fn put_i64(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'cyclic']
pub fn cyclic(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 64 { return -1 }
		operation_count := int(input[0])
		if length != usize(1 + 2 * operation_count) { return -1 }
		mut values := [64]i64{}
		mut next := [64]i64{}
		mut previous := [64]i64{}
		mut head := i64(-1)
		mut size := i64(0)
		mut allocated := 0
		mut records := [5000]i64{}
		mut record_fields := 0
		mut query_count := 0
		for index in 0 .. operation_count {
			operation, argument := input[1 + 2 * index], input[2 + 2 * index]
			if operation < 0 || operation > 5 { return -1 }
			if operation == 0 {
				if argument < -2147483648 || argument > 2147483647 || allocated >= 64 { return -1 }
				node := allocated
				allocated++
				values[node] = argument
				if size == 0 { head = i64(node); next[node] = head; previous[node] = head }
				else {
					tail := int(previous[int(head)])
					previous[node] = i64(tail); next[node] = head; next[tail] = i64(node); previous[int(head)] = i64(node)
				}
				size++
			} else if operation == 1 {
				if argument < -1000000 || argument > 1000000 { return -1 }
				rotate_list(next[0], previous[0], mut head, size, argument)
			} else if operation == 2 {
				if argument != 0 { return -1 }
				deleted := if delete_head(mut values[0], mut next[0], mut previous[0], mut head, mut size) { i64(1) } else { i64(0) }
				add_record(mut records[0], mut record_fields, i64(index)); add_record(mut records[0], mut record_fields, operation)
				add_record(mut records[0], mut record_fields, 1); add_record(mut records[0], mut record_fields, deleted); query_count++
			} else if operation == 3 {
				if argument != 0 { return -1 }
				add_record(mut records[0], mut record_fields, i64(index)); add_record(mut records[0], mut record_fields, operation); add_record(mut records[0], mut record_fields, size)
				mut cursor := head
				for _ in 0 .. int(size) { add_record(mut records[0], mut record_fields, values[int(cursor)]); cursor = next[int(cursor)] }
				query_count++
			} else if operation == 4 {
				if argument < -1000000 || argument > 1000000 || size == 0 { return -1 }
				for size > 1 { rotate_list(next[0], previous[0], mut head, size, argument); _ = delete_head(mut values[0], mut next[0], mut previous[0], mut head, mut size); rotate_list(next[0], previous[0], mut head, size, -1) }
				winner := values[int(head)]
				for delete_head(mut values[0], mut next[0], mut previous[0], mut head, mut size) {}
				add_record(mut records[0], mut record_fields, i64(index)); add_record(mut records[0], mut record_fields, operation)
				add_record(mut records[0], mut record_fields, 1); add_record(mut records[0], mut record_fields, winner); query_count++
			} else {
				if argument != 0 { return -1 }
				for delete_head(mut values[0], mut next[0], mut previous[0], mut head, mut size) {}
			}
		}
		required := (1 + record_fields + 1 + int(size)) * 8
		if output == nil || capacity < usize(required) { return -2 }
		mut field := 0
		put_i64(mut output, field * 8, i64(query_count)); field++
		for i in 0 .. record_fields { put_i64(mut output, field * 8, records[i]); field++ }
		put_i64(mut output, field * 8, size); field++
		mut cursor := head
		for _ in 0 .. int(size) { put_i64(mut output, field * 8, values[int(cursor)]); field++; cursor = next[int(cursor)] }
		return i64(required)
	}
}
