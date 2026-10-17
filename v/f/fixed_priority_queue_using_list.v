module fixed_priority_queue_using_list

@[export: 'fixed_priority_queue_using_list']
pub fn fixed_priority_queue_using_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 770 { return -1 }
	unsafe {
		operation_count := input[0]
		if operation_count < 0 || operation_count > 256 || length != usize(1 + 3*operation_count) { return -1 }
		mut buckets := [3][100]i32{}
		mut counts := [3]int{}
		mut dequeued := [128]i64{}
		mut dequeued_count := 0
		for i in 0 .. int(operation_count) {
			opcode, priority, data := input[1+3*i], input[2+3*i], input[3+3*i]
			if opcode == 0 {
				if priority < -3 || priority > 2 || data < -2147483648 || data > 2147483647 { return -1 }
				bucket := int(if priority < 0 { priority + 3 } else { priority })
				if counts[bucket] == 100 { return -1 }
				buckets[bucket][counts[bucket]] = i32(data)
				counts[bucket]++
			} else if opcode == 1 {
				if priority != 0 || data != 0 { return -1 }
				mut bucket := 0
				for bucket < 3 && counts[bucket] == 0 { bucket++ }
				if bucket == 3 { return -1 }
				dequeued[dequeued_count] = i64(buckets[bucket][0])
				dequeued_count++
				counts[bucket]--
				for j in 0 .. counts[bucket] { buckets[bucket][j] = buckets[bucket][j+1] }
			} else { return -1 }
		}
		output_bytes := dequeued_count * 8
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. dequeued_count {
			bits := u64(dequeued[i])
			for byte in 0 .. 8 { output[i*8+byte] = u8((bits >> u64(8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
