module stack_using_two_queues

@[export: 'stack_using_two_queues']
pub fn stack_using_two_queues(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 257 { return -1 }
	if unsafe { input[0] < 0 || input[0] > 128 || length != usize(1 + 2 * input[0]) } { return -1 }
	mut main_queue := []i64{len: 128}
	mut temp_queue := []i64{len: 128}
	mut head := 0
	mut tail := 0
	mut tags := [128]i64{}
	mut results := [128]i64{}
	mut record_count := 0
	mut pos := 1
	for _ in 0 .. int(unsafe { input[0] }) {
		opcode := unsafe { input[pos] }
		operand := unsafe { input[pos + 1] }
		pos += 2
		if opcode == 0 {
			if operand < -2147483648 || operand > 2147483647 { return -1 }
			mut temp_tail := 0
			temp_queue[temp_tail] = operand
			temp_tail++
			for head < tail {
				temp_queue[temp_tail] = main_queue[head]
				temp_tail++
				head++
			}
			main_queue, temp_queue = temp_queue, main_queue
			head = 0
			tail = temp_tail
		} else if opcode == 1 {
			if operand != 0 || head == tail { return -1 }
			tags[record_count] = 0
			results[record_count] = main_queue[head]
			record_count++
			head++
		} else if opcode == 2 {
			if operand != 0 { return -1 }
			if head == tail { tags[record_count] = 1; results[record_count] = 0 }
			else { tags[record_count] = 0; results[record_count] = main_queue[head] }
			record_count++
		} else { return -1 }
	}
	bytes := record_count * 16
	if unsafe { output == nil } || output_capacity < bytes { return -2 }
	for i in 0 .. record_count {
		tag_bits := u64(tags[i])
		value_bits := u64(results[i])
		for b in 0 .. 8 {
			unsafe {
				output[16 * i + b] = u8(tag_bits >> (8 * b))
				output[16 * i + 8 + b] = u8(value_bits >> (8 * b))
			}
		}
	}
	return i64(bytes)
}
