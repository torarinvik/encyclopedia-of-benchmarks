module fair_share_scheduling

fn store_i64_le(mut output &u8, position int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8(bits & 0xff) }
		bits >>= 8
	}
}

@[export: 'fair_share_scheduling']
pub fn fair_share_scheduling(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 3 || length > 323 { return -2 }
	unsafe {
		if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 128
			|| values[2] < 0 || values[2] > 1000000 { return -2 }
		user_count, task_count := int(values[0]), int(values[1])
		resources := values[2]
		if length != usize(3 + user_count + 2 * task_count) { return -2 }
		mut ids := [64]i64{}
		mut weights := [64]i64{}
		mut order := [64]int{}
		for user in 0 .. user_count {
			id := values[3 + user]
			if id < 0 || id > 63 { return -2 }
			for previous in 0 .. user {
				if ids[previous] == id { return -2 }
			}
			ids[user], order[user] = id, user
		}
		task_start := 3 + user_count
		for task in 0 .. task_count {
			owner, weight := values[task_start + 2 * task], values[task_start + 2 * task + 1]
			if owner < 0 || owner > 63 || weight < 0 || weight > 1000000 { return -2 }
			for user in 0 .. user_count {
				if ids[user] == owner {
					weights[user] += weight
					break
				}
			}
		}
		for i in 1 .. user_count {
			key := order[i]
			mut j := i
			for j > 0 && ids[order[j - 1]] > ids[key] {
				order[j] = order[j - 1]
				j--
			}
			order[j] = key
		}
		mut total_weight := i64(0)
		for user in 0 .. user_count { total_weight += weights[user] }
		required := user_count * 24
		if output_capacity < usize(required) || (required > 0 && output == nil) { return -2 }
		for position in 0 .. user_count {
			user := order[position]
			mut allocation := i64(0)
			if total_weight != 0 { allocation = weights[user] * resources / total_weight }
			store_i64_le(mut output, position * 24, ids[user])
			store_i64_le(mut output, position * 24 + 8, weights[user])
			store_i64_le(mut output, position * 24 + 16, allocation)
		}
		return i64(user_count)
	}
}
