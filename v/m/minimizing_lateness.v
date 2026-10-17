module minimizing_lateness

const max_jobs = 64
const max_output = 4 + 12 * max_jobs

struct Job {
	processing i32
	deadline i32
	original_index i32
	start_time i32
	lateness i32
}

fn write_i32(mut output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe {
		for byte in 0 .. 4 {
			output[offset + byte] = u8((bits >> (8 * byte)) & 255)
		}
	}
}

@[export: 'minimizing_lateness']
pub fn minimizing_lateness(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(1 + 2 * max_jobs) { return -1 }
		count_value := input[0]
		if count_value < 0 || count_value > max_jobs || length != usize(1 + 2 * count_value) { return -1 }
		count := int(count_value)
		mut jobs := [max_jobs]Job{}
		mut total_processing := i64(0)
		for i in 0 .. count {
			processing := input[1 + 2 * i]
			deadline := input[2 + 2 * i]
			if processing < 0 || processing > 2147483647 || deadline < 0 || deadline > 2147483647 { return -1 }
			total_processing += processing
			if total_processing > 2147483647 { return -1 }
			jobs[i] = Job{ i32(processing), i32(deadline), i32(i), 0, 0 }
		}
		// Stable insertion sort keeps the input order for equal deadlines.
		mut i := 1
		for i < count {
			item := jobs[i]
			mut position := i
			for position > 0 && jobs[position - 1].deadline > item.deadline {
				jobs[position] = jobs[position - 1]
				position--
			}
			jobs[position] = item
			i++
		}
		mut start_time := i64(0)
		for i in 0 .. count {
			jobs[i].start_time = i32(start_time)
			finish_time := start_time + i64(jobs[i].processing)
			late := finish_time - i64(jobs[i].deadline)
			jobs[i].lateness = i32(if late > 0 { late } else { 0 })
			start_time = finish_time
		}
		needed := usize(4 + 12 * count)
		if output == nil || output_capacity < needed { return -2 }
		mut payload := [max_output]u8{}
		write_i32(mut payload[0], 0, i32(count))
		for i in 0 .. count {
			offset := 4 + 12 * i
			write_i32(mut payload[0], offset, jobs[i].original_index)
			write_i32(mut payload[0], offset + 4, jobs[i].start_time)
			write_i32(mut payload[0], offset + 8, jobs[i].lateness)
		}
		for i in 0 .. int(needed) { output[i] = payload[i] }
		return i64(needed)
	}
}
