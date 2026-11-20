package packet_switching_random_schedule

import "core:c"

MAX_QUEUES :: 4
MAX_BUFFER :: 4
MAX_SLOTS :: 8
MAX_PARSEABLE_INPUT :: 68
MAX_OUTPUT_BYTES :: 64

Tag :: struct { priority: i64, marked: bool }

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
packet_switching_random_schedule :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT do return -1
	mv, bv, tv := input[0], input[1], input[2]
	if mv < 2 || mv > MAX_QUEUES || bv < 1 || bv > MAX_BUFFER || tv < 1 || tv > MAX_SLOTS do return -1
	m, b, slots := int(mv), int(bv), int(tv)
	cells := m * slots
	if length != c.size_t(3 + 2 * cells) do return -1
	for cell := 0; cell < cells; cell += 1 {
		flag, priority := input[3+cell], input[3+cells+cell]
		if flag < 0 || flag > 1 || priority < 0 || priority > 4294967295 do return -1
	}
	loads: [MAX_QUEUES]int
	counts: [MAX_QUEUES]int
	tags: [MAX_QUEUES][MAX_BUFFER]Tag
	trace: [MAX_SLOTS]i64
	for slot := 0; slot < slots; slot += 1 {
		for q := 0; q < m; q += 1 {
			cell := slot * m + q
			if input[3+cell] == 0 || loads[q] == b do continue
			if counts[q] == b {
				for i := 1; i < counts[q]; i += 1 { tags[q][i-1] = tags[q][i] }
				counts[q] -= 1
			}
			tags[q][counts[q]] = Tag{input[3+cells+cell], false}
			counts[q] += 1
			loads[q] += 1
		}
		best_q, best_i := m, 0
		best_priority: i64 = -1
		for q := 0; q < m; q += 1 {
			for i := 0; i < counts[q]; i += 1 {
				if tags[q][i].marked do continue
				if best_q == m || tags[q][i].priority > best_priority {
					best_q, best_i, best_priority = q, i, tags[q][i].priority
				}
			}
		}
		if best_q < m { tags[best_q][best_i].marked = true }
		else {
			best_q = m
			for q := 0; q < m; q += 1 { if loads[q] > 0 { best_q = q; break } }
		}
		if best_q == m { trace[slot] = -1 }
		else { trace[slot] = i64(best_q); loads[best_q] -= 1 }
	}
	output_bytes := 8 * slots
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for slot := 0; slot < slots; slot += 1 { store_i64_le(&staged[0], 8*slot, trace[slot]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
