module rate_monotonic_scheduling

const max_tasks = 8
const max_input = 17
const max_output_bytes = 80

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'rate_monotonic_scheduling']
pub fn rate_monotonic_scheduling(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		count_value := input[0]
		if count_value < 1 || count_value > max_tasks || length != usize(1 + 2 * count_value) { return -1 }
		count := int(count_value)
		mut execution := [max_tasks]i64{init: 0}
		mut period := [max_tasks]i64{init: 0}
		mut order := [max_tasks]int{init: 0}
		mut response := [max_tasks]i64{init: -1}
		for task in 0 .. count {
			execution[task], period[task] = input[1 + 2*task], input[2 + 2*task]
			if execution[task] < 1 || execution[task] > 16 || period[task] < 1 || period[task] > 32 { return -1 }
			order[task] = task
		}
		for index in 1 .. count {
			key := order[index]
			mut position := index
			for position > 0 && (period[order[position-1]] > period[key] ||
				(period[order[position-1]] == period[key] && order[position-1] > key)) {
				order[position] = order[position-1]
				position--
			}
			order[position] = key
		}

		mut schedulable := i64(1)
		mut failed_task := i64(-1)
		for rank in 0 .. count {
			target := order[rank]
			mut remaining_target := execution[target]
			mut active := [max_tasks]i64{init: 0}
			mut elapsed := i64(0)
			for remaining_target > 0 && elapsed < period[target] {
				for higher_rank in 0 .. rank {
					higher := order[higher_rank]
					if elapsed % period[higher] == 0 { active[higher] += execution[higher] }
				}
				mut selected := -1
				for higher_rank in 0 .. rank {
					higher := order[higher_rank]
					if active[higher] > 0 { selected = higher; break }
				}
				if selected >= 0 { active[selected]-- } else { remaining_target-- }
				elapsed++
			}
			if remaining_target > 0 { schedulable, failed_task = 0, i64(target); break }
			response[target] = elapsed
		}

		output_bytes := 8 * (count + 2)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		store_i64_le(mut staged[..], 0, schedulable)
		store_i64_le(mut staged[..], 8, failed_task)
		for task in 0 .. count { store_i64_le(mut staged[..], 8 * (task + 2), response[task]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
