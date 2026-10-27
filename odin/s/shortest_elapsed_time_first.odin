package shortest_elapsed_time_first

import "core:c"

MAX_JOBS :: 8
MAX_INPUT :: 18
MAX_OUTPUT :: 112

@(export)
shortest_elapsed_time_first :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 0 || n64 > MAX_JOBS || length != c.size_t(1+2*n64) do return -1
	n := int(n64)
	var release, remaining, attained: [MAX_JOBS]i64
	for job := 0; job < n; job += 1 {
		release[job] = input[1+2*job]
		remaining[job] = input[2+2*job]
		if release[job] < 0 || release[job] > 16 || remaining[job] < 1 || remaining[job] > 12 do return -1
	}
	if output == nil do return -2
	var trace: [MAX_OUTPUT]u8
	time, completed := 0, 0
	for completed < n && time < MAX_OUTPUT {
		chosen := n
		for job := 0; job < n; job += 1 {
			if release[job] <= i64(time) && remaining[job] > 0 &&
				(chosen == n || attained[job] < attained[chosen]) do chosen = job
		}
		if chosen < n {
			trace[time] = u8(chosen+1)
			attained[chosen] += 1
			remaining[chosen] -= 1
			if remaining[chosen] == 0 do completed += 1
		}
		time += 1
	}
	if completed != n do return -1
	if capacity < c.size_t(time) do return -2
	for t := 0; t < time; t += 1 do output[t] = trace[t]
	return i64(time)
}
