module cpu_scheduling_algorithms

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'cpu_scheduling_algorithms']
pub fn cpu_scheduling_algorithms(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 3 + 4 * 32 { return -1 }
	unsafe {
		mode := input[0]
		raw_count := input[1]
		quantum := input[2]
		if mode < 0 || mode > 5 || raw_count < 0 || raw_count > 32 || quantum < 1 || quantum > 32 { return -1 }
		n := int(raw_count)
		if length != usize(3 + 4 * n) { return -1 }

		mut ids := [32]i64{}
		mut arrival := [32]i64{}
		mut burst := [32]i64{}
		mut priority := [32]i64{}
		mut remaining := [32]i64{}
		mut completion := [32]i64{}
		mut first_run := [32]i64{}
		mut order := [32]int{}
		for i in 0 .. n {
			base := 3 + 4 * i
			ids[i] = input[base]
			arrival[i] = input[base + 1]
			burst[i] = input[base + 2]
			priority[i] = input[base + 3]
			if ids[i] < 0 || ids[i] >= 32 || arrival[i] < 0 || arrival[i] > 256 ||
				burst[i] < 1 || burst[i] > 32 || priority[i] < -32 || priority[i] > 32 { return -1 }
			for j in 0 .. i { if ids[j] == ids[i] { return -1 } }
			remaining[i] = burst[i]
			completion[i] = -1
			first_run[i] = -1
			order[i] = i
		}
		bytes := n * 56
		if bytes > 0 && (output == nil || capacity < usize(bytes)) { return -2 }

		if mode == 0 || mode == 5 {
			mut i := 1
			for i < n {
				key := order[i]
				mut j := i
				for j > 0 && arrival[order[j - 1]] > arrival[key] {
					order[j] = order[j - 1]
					j--
				}
				order[j] = key
				i++
			}
		}

		mut time := i64(0)
		if mode == 0 {
			for position in 0 .. n {
				i := order[position]
				if time < arrival[i] { time = arrival[i] }
				first_run[i] = time
				time += burst[i]
				completion[i] = time
			}
		} else if mode == 1 || mode == 3 {
			mut done := 0
			for done < n {
				mut best := n
				for i in 0 .. n {
					if completion[i] >= 0 || arrival[i] > time { continue }
					mut better := best == n
					if !better && mode == 1 {
						better = burst[i] < burst[best] || (burst[i] == burst[best] &&
							(arrival[i] < arrival[best] || (arrival[i] == arrival[best] && i < best)))
					} else if !better {
						better = priority[i] < priority[best] || (priority[i] == priority[best] && i < best)
					}
					if better { best = i }
				}
				if best == n { time++; continue }
				first_run[best] = time
				time += burst[best]
				completion[best] = time
				done++
			}
		} else if mode == 2 || mode == 4 {
			mut done := 0
			for done < n {
				mut best := n
				for i in 0 .. n {
					if remaining[i] <= 0 || arrival[i] > time { continue }
					mut better := best == n
					if !better && mode == 2 {
						better = remaining[i] < remaining[best] || (remaining[i] == remaining[best] &&
							(arrival[i] < arrival[best] || (arrival[i] == arrival[best] && i < best)))
					} else if !better {
						better = priority[i] < priority[best] || (priority[i] == priority[best] && i < best)
					}
					if better { best = i }
				}
				if best == n { time++; continue }
				if first_run[best] < 0 { first_run[best] = time }
				remaining[best]--
				time++
				if remaining[best] == 0 { completion[best] = time; done++ }
			}
		} else {
			mut queue := [64]int{}
			mut head := 0
			mut tail := 0
			mut queue_size := 0
			mut next_arrival := 0
			mut done := 0
			for done < n {
				for next_arrival < n && arrival[order[next_arrival]] <= time {
					queue[tail] = order[next_arrival]
					next_arrival++
					tail = (tail + 1) % 64
					queue_size++
				}
				if queue_size == 0 { time++; continue }
				current := queue[head]
				head = (head + 1) % 64
				queue_size--
				run_for := int(quantum)
				if remaining[current] < i64(run_for) { run_for = int(remaining[current]) }
				for _ in 0 .. run_for {
					if first_run[current] < 0 { first_run[current] = time }
					remaining[current]--
					time++
					for next_arrival < n && arrival[order[next_arrival]] <= time {
						queue[tail] = order[next_arrival]
						next_arrival++
						tail = (tail + 1) % 64
						queue_size++
					}
				}
				if remaining[current] > 0 {
					queue[tail] = current
					tail = (tail + 1) % 64
					queue_size++
				} else {
					completion[current] = time
					done++
				}
			}
		}

		for i in 0 .. n {
			turnaround := completion[i] - arrival[i]
			put_i64_le(mut output, i * 56, ids[i])
			put_i64_le(mut output, i * 56 + 8, arrival[i])
			put_i64_le(mut output, i * 56 + 16, burst[i])
			put_i64_le(mut output, i * 56 + 24, completion[i])
			put_i64_le(mut output, i * 56 + 32, turnaround)
			put_i64_le(mut output, i * 56 + 40, turnaround - burst[i])
			put_i64_le(mut output, i * 56 + 48, first_run[i] - arrival[i])
		}
		return i64(bytes)
	}
}
