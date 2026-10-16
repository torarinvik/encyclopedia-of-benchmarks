const max_requests = 64
const max_cylinder_count = 128

fn sort_ascending(mut items [64]i64, count int) {
	for index := 1; index < count; index++ {
		value := items[index]
		mut position := index
		for position > 0 && items[position - 1] > value {
			items[position] = items[position - 1]
			position--
		}
		items[position] = value
	}
}

@[export: 'circular_look_scheduling']
pub fn circular_look_scheduling(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 4 || length > usize(4 + max_requests) { return -1 }
		max_cylinder := values[0]
		start := values[1]
		moving_up := values[2]
		request_count := values[3]
		if max_cylinder < 1 || max_cylinder > max_cylinder_count || start < 0 || start >= max_cylinder ||
			(moving_up != 0 && moving_up != 1) || request_count < 0 || request_count > i64(max_requests) ||
			length != usize(4 + request_count) { return -1 }

		mut up := [64]i64{}
		mut down := [64]i64{}
		mut up_count := 0
		mut down_count := 0
		for index := 0; index < int(request_count); index++ {
			request := values[4 + index]
			if request < -128 || request > 255 { return -1 }
			if request < 0 || request >= max_cylinder || request == start { continue }
			if request > start {
				up[up_count] = request
				up_count++
			} else {
				down[down_count] = request
				down_count++
			}
		}
		sort_ascending(mut up, up_count)
		sort_ascending(mut down, down_count)

		output_count := up_count + down_count
		if output_capacity < usize(output_count) || (output_count > 0 && output == nil) { return -2 }
		mut position := 0
		if moving_up == 1 {
			for index := 0; index < up_count; index++ {
				output[position] = u8(up[index])
				position++
			}
			for index := 0; index < down_count; index++ {
				output[position] = u8(down[index])
				position++
			}
		} else {
			for index := down_count; index > 0; index-- {
				output[position] = u8(down[index - 1])
				position++
			}
			for index := up_count; index > 0; index-- {
				output[position] = u8(up[index - 1])
				position++
			}
		}
		return i64(output_count)
	}
}
