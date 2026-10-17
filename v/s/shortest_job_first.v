module shortest_job_first

const max_jobs = 32
const sentinel = i64(999999999)

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'shortest_job_first']
pub fn shortest_job_first(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		raw_count := input[0]
		if raw_count < 0 || raw_count > max_jobs || length != usize(1 + 2 * raw_count) { return -1 }
		count := int(raw_count)
		mut remaining := [32]i64{}
		mut waiting := [32]i64{}
		for i in 0 .. count {
			arrival := input[1 + i]
			burst := input[1 + count + i]
			if arrival < 0 || arrival > 64 || burst < 1 || burst > 128 || burst >= sentinel { return -1 }
			remaining[i] = burst
		}
		bytes := (1 + 2 * count) * 8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		mut complete := 0
		mut time := i64(0)
		mut minimum := sentinel
		mut short_index := 0
		mut check := false
		for complete != count {
			for j in 0 .. count {
				if input[1 + j] <= time && remaining[j] > 0 && remaining[j] < minimum {
					minimum = remaining[j]
					short_index = j
					check = true
				}
			}
			if !check { time++ ; continue }
			remaining[short_index]--
			minimum = remaining[short_index]
			if minimum == 0 { minimum = sentinel }
			if remaining[short_index] == 0 {
				complete++
				check = false
				wait := time + 1 - input[1 + short_index] - input[1 + count + short_index]
				if wait < 0 { wait = 0 }
				waiting[short_index] = wait
			}
			time++
		}
		put_i64_le(mut output, 0, raw_count)
		for i in 0 .. count { put_i64_le(mut output, 8 * (1 + i), waiting[i]) }
		for i in 0 .. count { put_i64_le(mut output, 8 * (1 + count + i), input[1 + count + i] + waiting[i]) }
		return i64(bytes)
	}
}
