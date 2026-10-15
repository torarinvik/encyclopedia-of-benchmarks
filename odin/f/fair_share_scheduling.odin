package fair_share_scheduling

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, position: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 {
		output[position + byte] = u8((bits >> (byte * 8)) & 0xff)
	}
}

@(export)
fair_share_scheduling :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 323 do return -2
	if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 128 ||
			values[2] < 0 || values[2] > 1_000_000 {
		return -2
	}
	user_count, task_count := c.size_t(values[0]), c.size_t(values[1])
	resources := values[2]
	if length != 3 + user_count + 2 * task_count do return -2

	ids: [64]i64
	weights: [64]i64
	order: [64]c.size_t
	for user: c.size_t = 0; user < user_count; user += 1 {
		id := values[3 + user]
		if id < 0 || id > 63 do return -2
		for previous: c.size_t = 0; previous < user; previous += 1 {
			if ids[previous] == id do return -2
		}
		ids[user], order[user] = id, user
	}
	task_start := 3 + user_count
	for task: c.size_t = 0; task < task_count; task += 1 {
		owner, weight := values[task_start + 2 * task], values[task_start + 2 * task + 1]
		if owner < 0 || owner > 63 || weight < 0 || weight > 1_000_000 do return -2
		for user: c.size_t = 0; user < user_count; user += 1 {
			if ids[user] == owner {
				weights[user] += weight
				break
			}
		}
	}
	for i: c.size_t = 1; i < user_count; i += 1 {
		key := order[i]
		j := i
		for j > 0 && ids[order[j - 1]] > ids[key] {
			order[j] = order[j - 1]
			j -= 1
		}
		order[j] = key
	}
	total_weight: i64 = 0
	for user: c.size_t = 0; user < user_count; user += 1 { total_weight += weights[user] }
	required := user_count * 24
	if output_capacity < required || (required != 0 && output == nil) do return -2
	for position: c.size_t = 0; position < user_count; position += 1 {
		user := order[position]
		allocation: i64 = 0
		if total_weight != 0 { allocation = weights[user] * resources / total_weight }
		store_i64_le(output, position * 24, ids[user])
		store_i64_le(output, position * 24 + 8, weights[user])
		store_i64_le(output, position * 24 + 16, allocation)
	}
	return i64(user_count)
}
