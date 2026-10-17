package shortest_job_first

import "core:c"

MAX_JOBS :: 32
SENTINEL :: i64(999999999)

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
shortest_job_first :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	raw_count := input[0]
	if raw_count < 0 || raw_count > MAX_JOBS || length != c.size_t(1+2*raw_count) do return -1
	count := int(raw_count)
	remaining: [MAX_JOBS]i64 = {}
	waiting: [MAX_JOBS]i64 = {}
	for i := 0; i < count; i += 1 {
		arrival, burst := input[1+i], input[1+count+i]
		if arrival < 0 || arrival > 64 || burst < 1 || burst > 128 || burst >= SENTINEL do return -1
		remaining[i] = burst
	}
	bytes := (1+2*count)*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	complete := 0
	time: i64 = 0
	minimum := SENTINEL
	short_index := 0
	check := false
	for complete != count {
		for j := 0; j < count; j += 1 {
			if input[1+j] <= time && remaining[j] > 0 && remaining[j] < minimum {
				minimum = remaining[j]
				short_index = j
				check = true
			}
		}
		if !check { time += 1; continue }
		remaining[short_index] -= 1
		minimum = remaining[short_index]
		if minimum == 0 do minimum = SENTINEL
		if remaining[short_index] == 0 {
			complete += 1
			check = false
			wait := time + 1 - input[1+short_index] - input[1+count+short_index]
			if wait < 0 do wait = 0
			waiting[short_index] = wait
		}
		time += 1
	}
	put_i64_le(output,0,raw_count)
	for i := 0; i < count; i += 1 { put_i64_le(output,8*(1+i),waiting[i]) }
	for i := 0; i < count; i += 1 { put_i64_le(output,8*(1+count+i),input[1+count+i]+waiting[i]) }
	return i64(bytes)
}
