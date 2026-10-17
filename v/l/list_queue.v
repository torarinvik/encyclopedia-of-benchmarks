module list_queue

const max_queue_size = 10
const max_ops = 64
const max_input_length = 129
const max_output_words = 130
const max_output_bytes = 520

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'list_queue']
pub fn list_queue(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		if input[0] < 0 || input[0] > max_ops { return -1 }
		op_count := int(input[0])
		mut queue := [max_queue_size]i32{}
		mut words := [max_output_words]i32{}
		mut word_count := 1
		mut query_count := 0
		mut pos := 1
		mut queue_size := 0
		for _ in 0 .. op_count {
			if pos >= int(length) { return -1 }
			opcode := input[pos]
			pos++
			if opcode == 0 {
				if pos >= int(length) { return -1 }
				raw := input[pos]
				pos++
				if raw < -2147483648 || raw > 2147483647 || queue_size >= max_queue_size { return -1 }
				queue[queue_size] = i32(raw)
				queue_size++
			} else if opcode == 1 {
				if queue_size == 0 {
					words[word_count] = 3
					words[word_count + 1] = 0
				} else {
					value := queue[0]
					for i in 0 .. max_queue_size - 1 { queue[i] = queue[i + 1] }
					queue_size--
					words[word_count] = 1
					words[word_count + 1] = value
				}
				word_count += 2
				query_count++
			} else if opcode == 2 {
				words[word_count] = 2
				words[word_count + 1] = i32(queue_size)
				word_count += 2
				query_count++
			} else { return -1 }
		}
		if pos != int(length) || word_count + 1 + queue_size > max_output_words { return -1 }
		words[0] = i32(query_count)
		words[word_count] = i32(queue_size)
		word_count++
		for i in 0 .. queue_size {
			words[word_count] = queue[i]
			word_count++
		}
		bytes := word_count * 4
		if output == nil || capacity < usize(bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		for i in 0 .. word_count { put_i32_le(mut buffer[0], i * 4, words[i]) }
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
