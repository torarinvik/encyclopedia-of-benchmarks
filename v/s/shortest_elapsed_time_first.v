module shortest_elapsed_time_first

const max_jobs = 8
const max_input = 18
const max_output = 112

@[export: 'shortest_elapsed_time_first']
pub fn shortest_elapsed_time_first(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input { return -1 }
		n64 := input[0]
		if n64 < 0 || n64 > max_jobs || length != usize(1+2*n64) { return -1 }
		n := int(n64)
		mut release := []i64{len: max_jobs, init: 0}
		mut remaining := []i64{len: max_jobs, init: 0}
		mut attained := []i64{len: max_jobs, init: 0}
		for job in 0 .. n {
			release[job] = input[1+2*job]
			remaining[job] = input[2+2*job]
			if release[job] < 0 || release[job] > 16 || remaining[job] < 1 || remaining[job] > 12 { return -1 }
		}
		if output == nil { return -2 }
		mut trace := []u8{len: max_output, init: 0}
		mut time := 0
		mut completed := 0
		for completed < n && time < max_output {
			mut chosen := n
			for job in 0 .. n {
				if release[job] <= i64(time) && remaining[job] > 0 &&
					(chosen == n || attained[job] < attained[chosen]) { chosen = job }
			}
			if chosen < n {
				trace[time] = u8(chosen+1)
				attained[chosen]++
				remaining[chosen]--
				if remaining[chosen] == 0 { completed++ }
			}
			time++
		}
		if completed != n { return -1 }
		if capacity < time { return -2 }
		for t in 0 .. time { output[t] = trace[t] }
		return i64(time)
	}
}
