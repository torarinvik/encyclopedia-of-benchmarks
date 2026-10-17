module multi_level_feedback_queue

const max_queues = 4
const max_processes = 8
const max_input_words = 13
const max_output_words = 1 + 4 * max_processes
const max_output_bytes = 4 * max_output_words

struct Process {
	id        i32
	remaining  i32
	waiting   i32
	turnaround i32
	stop_time i32
}

fn put_i32_le(mut output &u8, offset int, value i32) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'multi_level_feedback_queue']
pub fn multi_level_feedback_queue(input &i32, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_words) { return -1 }
		queue_count := input[0]
		process_count := input[1]
		if queue_count < 1 || queue_count > max_queues || process_count < 0 || process_count > max_processes { return -1 }
		if length != usize(2 + queue_count - 1 + process_count) { return -1 }
		mut slices := [max_queues - 1]i32{}
		mut pos := 2
		for i in 0 .. int(queue_count - 1) {
			if input[pos] < 1 || input[pos] > 16 { return -1 }
			slices[i] = i32(input[pos])
			pos++
		}
		mut ready := [max_processes]Process{}
		mut ready_count := int(process_count)
		for i in 0 .. int(process_count) {
			burst := input[pos]
			pos++
			if burst < 1 || burst > 16 { return -1 }
			ready[i] = Process{i32(i), i32(burst), 0, 0, 0}
		}
		mut finished := [max_processes]Process{}
		mut finished_count := 0
		mut current_time := i32(0)
		for level in 0 .. int(queue_count - 1) {
			mut next_ready := [max_processes]Process{}
			mut next_count := 0
			time_slice := slices[level]
			for i in 0 .. ready_count {
				mut process := ready[i]
				process.waiting += current_time - process.stop_time
				if process.remaining > time_slice {
					current_time += time_slice
					process.remaining -= time_slice
					process.stop_time = current_time
					next_ready[next_count] = process
					next_count++
				} else {
					current_time += process.remaining
					process.remaining = 0
					process.stop_time = current_time
					process.turnaround = current_time
					finished[finished_count] = process
					finished_count++
				}
			}
			ready_count = next_count
			for i in 0 .. next_count { ready[i] = next_ready[i] }
		}
		for i in 0 .. ready_count {
			mut process := ready[i]
			process.waiting += current_time - process.stop_time
			current_time += process.remaining
			process.remaining = 0
			process.stop_time = current_time
			process.turnaround = current_time
			finished[finished_count] = process
			finished_count++
		}
		if finished_count != int(process_count) { return -1 }
		mut words := [max_output_words]i32{}
		words[0] = i32(process_count)
		mut word_count := 1
		for i in 0 .. finished_count {
			words[word_count] = finished[i].id
			words[word_count + 1] = finished[i].waiting
			words[word_count + 2] = finished[i].turnaround
			words[word_count + 3] = finished[i].stop_time
			word_count += 4
		}
		bytes := word_count * 4
		if bytes > max_output_bytes || output == nil || output_capacity < usize(bytes) { return -2 }
		mut buffer := [max_output_bytes]u8{}
		for i in 0 .. word_count { put_i32_le(mut buffer[0], i * 4, words[i]) }
		for i in 0 .. bytes { output[i] = buffer[i] }
		return i64(bytes)
	}
}
