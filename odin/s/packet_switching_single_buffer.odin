package packet_switching_single_buffer

import "core:c"

MAX_PACKETS :: 16
MAX_SLOTS :: 8
MAX_INPUT :: 38
MAX_OUTPUT_BYTES :: 64
BETA :: 15

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

erase_packet :: proc(ids: ^[MAX_PACKETS]i64, values: ^[MAX_PACKETS]i64, count: ^int, index: int) {
	for position := index; position+1 < count^; position += 1 {
		ids^[position] = ids^[position+1]
		values^[position] = values^[position+1]
	}
	count^ -= 1
}

@(export)
packet_switching_single_buffer :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	mode, buffer, beta, slots_value, count_value := input[0], input[1], input[2], input[3], input[4]
	if mode < 0 || mode > 2 || buffer < 1 || buffer > 4 || slots_value < 1 || slots_value > MAX_SLOTS ||
		count_value < 0 || count_value > MAX_PACKETS || length != c.size_t(5 + 2*count_value) ||
		(mode == 0 && beta != 0) || (mode != 0 && beta != BETA) do return -1
	slots, packet_count := int(slots_value), int(count_value)
	arrival: [MAX_PACKETS]i64
	packet_value: [MAX_PACKETS]i64
	previous_slot := i64(-1)
	for packet := 0; packet < packet_count; packet += 1 {
		arrival[packet], packet_value[packet] = input[5+2*packet], input[6+2*packet]
		if arrival[packet] < 0 || arrival[packet] >= slots_value || arrival[packet] < previous_slot ||
			packet_value[packet] < 1 || packet_value[packet] > 100 do return -1
		previous_slot = arrival[packet]
	}
	resident_id: [MAX_PACKETS]i64
	resident_value: [MAX_PACKETS]i64
	schedule: [MAX_SLOTS]i64
	resident_count, next_packet := 0, 0
	for slot := 0; slot < slots; slot += 1 {
		for next_packet < packet_count && arrival[next_packet] == i64(slot) {
			value := packet_value[next_packet]
			preempt := resident_count
			if mode == 1 {
				for index := 0; index < resident_count; index += 1 {
					if resident_value[index]*BETA <= value { preempt = index; break }
				}
			} else if mode == 2 {
				for index := 0; index < resident_count; index += 1 {
					following_ok := index+1 == resident_count || resident_value[index] <= resident_value[index+1]
					if resident_value[index]*BETA < value && following_ok { preempt = index; break }
				}
			}
			if preempt < resident_count {
				erase_packet(&resident_id, &resident_value, &resident_count, preempt)
				resident_id[resident_count], resident_value[resident_count] = i64(next_packet), value
				resident_count += 1
			} else if resident_count < int(buffer) {
				resident_id[resident_count], resident_value[resident_count] = i64(next_packet), value
				resident_count += 1
			} else {
				smallest := resident_value[0]
				for index := 1; index < resident_count; index += 1 { if resident_value[index] < smallest { smallest = resident_value[index] } }
				if value > smallest {
					evict := 0
					for resident_value[evict] != smallest { evict += 1 }
					erase_packet(&resident_id, &resident_value, &resident_count, evict)
					resident_id[resident_count], resident_value[resident_count] = i64(next_packet), value
					resident_count += 1
				}
			}
			next_packet += 1
		}
		if resident_count > 0 {
			schedule[slot] = resident_id[0]
			erase_packet(&resident_id, &resident_value, &resident_count, 0)
		} else { schedule[slot] = -1 }
	}
	output_bytes := 8*slots
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	for slot := 0; slot < slots; slot += 1 { store_i64_le(&staged[0], 8*slot, schedule[slot]) }
	for byte := 0; byte < output_bytes; byte += 1 { output[byte] = staged[byte] }
	return i64(output_bytes)
}
