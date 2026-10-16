package cpu_scheduling_algorithms

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits >> u64(8*byte))
	}
}

@(export)
cpu_scheduling_algorithms :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 3+4*32 { return -1 }
	mode, raw_count, quantum := input[0], input[1], input[2]
	if mode < 0 || mode > 5 || raw_count < 0 || raw_count > 32 || quantum < 1 || quantum > 32 { return -1 }
	n := int(raw_count)
	if length != c.size_t(3+4*n) { return -1 }

	ids: [32]i64
	arrival: [32]i64
	burst: [32]i64
	priority: [32]i64
	remaining: [32]i64
	completion: [32]i64
	first_run: [32]i64
	order: [32]int
	for i := 0; i < n; i += 1 {
		base := 3+4*i
		ids[i], arrival[i], burst[i], priority[i] = input[base], input[base+1], input[base+2], input[base+3]
		if ids[i] < 0 || ids[i] >= 32 || arrival[i] < 0 || arrival[i] > 256 ||
			burst[i] < 1 || burst[i] > 32 || priority[i] < -32 || priority[i] > 32 {
			return -1
		}
		for j := 0; j < i; j += 1 { if ids[j] == ids[i] do return -1 }
		remaining[i], completion[i], first_run[i], order[i] = burst[i], -1, -1, i
	}
	bytes := n*56
	if bytes > 0 && (output == nil || capacity < c.size_t(bytes)) do return -2

	if mode == 0 || mode == 5 {
		for i := 1; i < n; i += 1 {
			key, j := order[i], i
			for j > 0 && arrival[order[j-1]] > arrival[key] { order[j] = order[j-1]; j -= 1 }
			order[j] = key
		}
	}

	time: i64 = 0
	if mode == 0 {
		for position := 0; position < n; position += 1 {
			i := order[position]
			if time < arrival[i] do time = arrival[i]
			first_run[i], time = time, time+burst[i]
			completion[i] = time
		}
	} else if mode == 1 || mode == 3 {
		done := 0
		for done < n {
			best := n
			for i := 0; i < n; i += 1 {
				if completion[i] >= 0 || arrival[i] > time do continue
				better := best == n
				if !better && mode == 1 {
					better = burst[i] < burst[best] || (burst[i] == burst[best] &&
						(arrival[i] < arrival[best] || (arrival[i] == arrival[best] && i < best)))
				} else if !better {
					better = priority[i] < priority[best] || (priority[i] == priority[best] && i < best)
				}
				if better do best = i
			}
			if best == n { time += 1; continue }
			first_run[best] = time
			time += burst[best]
			completion[best] = time
			done += 1
		}
	} else if mode == 2 || mode == 4 {
		done := 0
		for done < n {
			best := n
			for i := 0; i < n; i += 1 {
				if remaining[i] <= 0 || arrival[i] > time do continue
				better := best == n
				if !better && mode == 2 {
					better = remaining[i] < remaining[best] || (remaining[i] == remaining[best] &&
						(arrival[i] < arrival[best] || (arrival[i] == arrival[best] && i < best)))
				} else if !better {
					better = priority[i] < priority[best] || (priority[i] == priority[best] && i < best)
				}
				if better do best = i
			}
			if best == n { time += 1; continue }
			if first_run[best] < 0 do first_run[best] = time
			remaining[best] -= 1
			time += 1
			if remaining[best] == 0 { completion[best] = time; done += 1 }
		}
	} else {
		queue: [64]int
		head, tail, queue_size, next_arrival, done := 0, 0, 0, 0, 0
		for done < n {
			for next_arrival < n && arrival[order[next_arrival]] <= time {
				queue[tail] = order[next_arrival]
				next_arrival += 1
				tail = (tail+1)%64
				queue_size += 1
			}
			if queue_size == 0 { time += 1; continue }
			current := queue[head]
			head = (head+1)%64
			queue_size -= 1
			run_for := quantum
			if remaining[current] < run_for do run_for = remaining[current]
			for slot := 0; slot < int(run_for); slot += 1 {
				if first_run[current] < 0 do first_run[current] = time
				remaining[current] -= 1
				time += 1
				for next_arrival < n && arrival[order[next_arrival]] <= time {
					queue[tail] = order[next_arrival]
					next_arrival += 1
					tail = (tail+1)%64
					queue_size += 1
				}
			}
			if remaining[current] > 0 {
				queue[tail] = current
				tail = (tail+1)%64
				queue_size += 1
			} else {
				completion[current] = time
				done += 1
			}
		}
	}

	for i := 0; i < n; i += 1 {
		turnaround := completion[i]-arrival[i]
		fields := [7]i64{ids[i], arrival[i], burst[i], completion[i], turnaround,
			turnaround-burst[i], first_run[i]-arrival[i]}
		for field := 0; field < 7; field += 1 do put_i64_le(output, i*56+field*8, fields[field])
	}
	return i64(bytes)
}
