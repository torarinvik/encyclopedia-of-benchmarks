module packet_switching_random_schedule

const max_queues = 4
const max_buffer = 4
const max_slots = 8
const max_parseable_input = 68
const max_output_bytes = 64

struct Tag {
mut:
	priority i64
	marked bool
}

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'packet_switching_random_schedule']
pub fn packet_switching_random_schedule(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_input { return -1 }
		m_value, b_value, slots_value := input[0], input[1], input[2]
		if m_value < 2 || m_value > max_queues || b_value < 1 || b_value > max_buffer || slots_value < 1 || slots_value > max_slots { return -1 }
		m, b, slots := int(m_value), int(b_value), int(slots_value)
		cells := m * slots
		if length != usize(3 + 2 * cells) { return -1 }
		for cell in 0 .. cells {
			flag, priority := input[3 + cell], input[3 + cells + cell]
			if flag < 0 || flag > 1 || priority < 0 || priority > 4294967295 { return -1 }
		}
		mut loads := [max_queues]int{init: 0}
		mut counts := [max_queues]int{init: 0}
		mut tags := [max_queues][max_buffer]Tag{}
		mut trace := [max_slots]i64{init: -1}
		for slot in 0 .. slots {
			for q in 0 .. m {
				cell := slot * m + q
				if input[3 + cell] == 0 || loads[q] == b { continue }
				if counts[q] == b {
					for i in 1 .. counts[q] { tags[q][i - 1] = tags[q][i] }
					counts[q]--
				}
				tags[q][counts[q]] = Tag{priority: input[3 + cells + cell], marked: false}
				counts[q]++
				loads[q]++
			}
			mut best_q := m
			mut best_i := 0
			mut best_priority := i64(-1)
			for q in 0 .. m {
				for i in 0 .. counts[q] {
					if tags[q][i].marked { continue }
					if best_q == m || tags[q][i].priority > best_priority {
						best_q, best_i, best_priority = q, i, tags[q][i].priority
					}
				}
			}
			if best_q < m { tags[best_q][best_i].marked = true }
			else {
				for q in 0 .. m { if loads[q] > 0 { best_q = q; break } }
			}
			if best_q < m { trace[slot] = i64(best_q); loads[best_q]-- }
		}
		output_bytes := 8 * slots
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output_bytes]u8{init: 0}
		for slot in 0 .. slots { store_i64_le(mut staged[..], 8 * slot, trace[slot]) }
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return i64(output_bytes)
	}
}
