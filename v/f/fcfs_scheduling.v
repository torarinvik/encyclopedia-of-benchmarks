module fcfs_scheduling

fn store_i64_le(mut output &u8, position int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8(bits & 0xff) }
		bits >>= 8
	}
}

@[export: 'fcfs_scheduling']
pub fn fcfs_scheduling(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 193 { return -2 }
	unsafe {
		if values[0] < 0 || values[0] > 64 { return -2 }
		count := int(values[0])
		if length != usize(1 + 3 * count) { return -2 }
		mut ids := [64]i64{}
		mut arrivals := [64]i64{}
		mut bursts := [64]i64{}
		mut order := [64]int{}
		for i in 0 .. count {
			id, arrival, burst := values[1 + 3 * i], values[2 + 3 * i], values[3 + 3 * i]
			if id < 0 || id > 63 || arrival < 0 || arrival > 1000000 || burst < 1 || burst > 1000000 {
				return -2
			}
			for previous in 0 .. i {
				if ids[previous] == id { return -2 }
			}
			ids[i], arrivals[i], bursts[i], order[i] = id, arrival, burst, i
		}
		for i in 1 .. count {
			key := order[i]
			mut j := i
			for j > 0 && (arrivals[order[j - 1]] > arrivals[key] ||
				(arrivals[order[j - 1]] == arrivals[key] && ids[order[j - 1]] > ids[key])) {
				order[j] = order[j - 1]
				j--
			}
			order[j] = key
		}
		required := count * 48
		if output_capacity < usize(required) || (required > 0 && output == nil) { return -2 }
		mut elapsed := i64(0)
		for position in 0 .. count {
			i := order[position]
			if elapsed < arrivals[i] { elapsed = arrivals[i] }
			completion := elapsed + bursts[i]
			turnaround := completion - arrivals[i]
			waiting := turnaround - bursts[i]
			store_i64_le(mut output, position * 48, ids[i])
			store_i64_le(mut output, position * 48 + 8, arrivals[i])
			store_i64_le(mut output, position * 48 + 16, bursts[i])
			store_i64_le(mut output, position * 48 + 24, completion)
			store_i64_le(mut output, position * 48 + 32, turnaround)
			store_i64_le(mut output, position * 48 + 40, waiting)
			elapsed = completion
		}
		return i64(count)
	}
}
