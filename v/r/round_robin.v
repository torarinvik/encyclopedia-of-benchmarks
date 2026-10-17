module round_robin

const max_jobs = 32
const quantum = i64(2)

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'round_robin']
pub fn round_robin(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		raw_count := input[0]
		if raw_count < 0 || raw_count > max_jobs || length != usize(raw_count + 1) { return -1 }
		count := int(raw_count)
		mut remaining := [32]i64{}
		mut waiting := [32]i64{}
		for i in 0 .. count {
			burst := input[i + 1]
			if burst < 0 || burst > 4096 { return -1 }
			remaining[i] = burst
		}
		bytes := (1 + 2 * count) * 8
		if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
		mut elapsed := i64(0)
		for {
			mut done := true
			for i in 0 .. count {
				if remaining[i] > 0 {
					done = false
					if remaining[i] > quantum {
						elapsed += quantum
						remaining[i] -= quantum
					} else {
						elapsed += remaining[i]
						waiting[i] = elapsed - input[i + 1]
						remaining[i] = 0
					}
				}
			}
			if done { break }
		}
		put_i64_le(mut output, 0, raw_count)
		for i in 0 .. count { put_i64_le(mut output, 8 * (1 + i), waiting[i]) }
		for i in 0 .. count { put_i64_le(mut output, 8 * (1 + count + i), input[i + 1] + waiting[i]) }
		return i64(bytes)
	}
}
