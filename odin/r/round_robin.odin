package round_robin

import "core:c"

MAX_JOBS :: 32
QUANTUM :: 2

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
round_robin :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > MAX_JOBS || length != c.size_t(raw_count+1) do return -1
	count := int(raw_count)
	remaining: [MAX_JOBS]i64
	waiting: [MAX_JOBS]i64
	for i := 0; i < count; i += 1 {
		burst := input[i+1]
		if burst < 0 || burst > 4096 do return -1
		remaining[i] = burst
	}
	bytes := (1+2*count)*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	elapsed: i64 = 0
	for {
		done := true
		for i := 0; i < count; i += 1 {
			if remaining[i] > 0 {
				done = false
				if remaining[i] > QUANTUM {
					elapsed += QUANTUM
					remaining[i] -= QUANTUM
				} else {
					elapsed += remaining[i]
					waiting[i] = elapsed-input[i+1]
					remaining[i] = 0
				}
			}
		}
		if done do break
	}
	put_i64_le(output,0,raw_count)
	for i := 0; i < count; i += 1 { put_i64_le(output,8*(1+i),waiting[i]) }
	for i := 0; i < count; i += 1 { put_i64_le(output,8*(1+count+i),input[i+1]+waiting[i]) }
	return i64(bytes)
}
