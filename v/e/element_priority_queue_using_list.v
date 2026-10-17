module element_priority_queue_using_list

@[export: 'element_priority_queue_using_list']
pub fn element_priority_queue_using_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 514 { return -1 }
	unsafe {
		operation_count := input[0]
		if operation_count < 0 || operation_count > 256 || length != usize(1 + 2*operation_count) { return -1 }
		mut queue := [100]i32{}
		mut queue_count := 0
		mut dequeued := [128]i64{}
		mut dequeued_count := 0
		for i in 0 .. int(operation_count) {
			opcode, argument := input[1+2*i], input[2+2*i]
			if opcode == 0 {
				if argument < -2147483648 || argument > 2147483647 || queue_count == 100 { return -1 }
				queue[queue_count] = i32(argument)
				queue_count++
			} else if opcode == 1 {
				if argument != 0 || queue_count == 0 { return -1 }
				mut minimum := 0
				for j in 1 .. queue_count { if queue[j] < queue[minimum] { minimum = j } }
				dequeued[dequeued_count] = i64(queue[minimum])
				dequeued_count++
				queue_count--
				for j in minimum .. queue_count { queue[j] = queue[j+1] }
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
