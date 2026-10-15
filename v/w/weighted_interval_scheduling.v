module weighted_interval_scheduling

const max_intervals = 64
const max_input_length = 193

fn start_at(input &i64, index int) i64 { unsafe { return input[1 + index * 3] } }
fn end_at(input &i64, index int) i64 { unsafe { return input[2 + index * 3] } }
fn weight_at(input &i64, index int) i64 { unsafe { return input[3 + index * 3] } }

fn put_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}
fn put_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe { for byte in 0 .. 4 { output[offset + byte] = u8((bits >> u32(8 * byte)) & 255) } }
}

@[export: 'weighted_interval_scheduling']
pub fn weighted_interval_scheduling(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_intervals { return -1 }
		n := int(input[0])
		if int(length) != 1 + 3 * n { return -1 }
		for i in 0 .. n {
			start := start_at(input, i); finish := end_at(input, i); weight := weight_at(input, i)
			if start < -100000 || start > 100000 || finish < -100000 || finish > 100000 || start >= finish || weight < 0 || weight > 1000000 { return -1 }
		}
		mut order := [max_intervals]int{}
		mut predecessors := [max_intervals]int{}
		mut selected := [max_intervals]int{}
		mut dp := [max_intervals + 1]i64{}
		for i in 0 .. n { order[i] = i }
		for i := 1; i < n; i++ {
			key := order[i]
			mut j := i
			for j > 0 && end_at(input, order[j - 1]) > end_at(input, key) { order[j] = order[j - 1]; j-- }
			order[j] = key
		}
		for j in 0 .. n {
			mut low := 0
			mut high := n
			for low < high {
				mid := low + (high - low) / 2
				if end_at(input, order[mid]) <= start_at(input, order[j]) { low = mid + 1 }
				else { high = mid }
			}
			predecessors[j] = low
			include := weight_at(input, order[j]) + dp[low]
			dp[j + 1] = if include > dp[j] { include } else { dp[j] }
		}
		mut selected_count := 0
		mut current := n
		for current > 0 {
			j := current - 1
			include := weight_at(input, order[j]) + dp[predecessors[j]]
			if include > dp[current - 1] { selected[selected_count] = order[j]; selected_count++; current = predecessors[j] }
			else { current-- }
		}
		for i in 0 .. selected_count / 2 {
			temp := selected[i]; selected[i] = selected[selected_count - 1 - i]; selected[selected_count - 1 - i] = temp
		}
		needed := 16 + 4 * selected_count
		if output == nil || capacity < usize(needed) { return -2 }
		put_i64_le(output, 0, dp[n]); put_i64_le(output, 8, i64(selected_count))
		for i in 0 .. selected_count { put_i32_le(output, 16 + 4 * i, i32(selected[i])) }
		return i64(needed)
	}
}
