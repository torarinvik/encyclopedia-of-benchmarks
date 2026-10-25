// Bounded clean-room TAR-header filename search benchmark.
// Embench-IoT source declares MIT; see the package attribution.
// SPDX-License-Identifier: MIT
module tarfind

const max_records = 35
const max_queries = 5
const min_name_length = 5
const max_name_length = 39
const max_input_length = 2 + max_records * (1 + max_name_length) + max_queries * (1 + max_name_length)

@[export: 'tarfind']
pub fn tarfind(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 2 || input_length > max_input_length { return -1 }
	if unsafe { input[0] < 1 || input[0] > max_records || input[1] < 1 || input[1] > max_queries } {
		return -1
	}
	record_count := int(unsafe { input[0] })
	query_count := int(unsafe { input[1] })
	mut record_offsets := [max_records]int{}
	mut record_lengths := [max_records]int{}
	mut query_offsets := [max_queries]int{}
	mut query_lengths := [max_queries]int{}
	mut staged := [max_queries]u8{}
	mut position := 2

	for i in 0 .. record_count {
		if position >= int(input_length) { return -1 }
		raw_length := unsafe { input[position] }
		position++
		if raw_length < min_name_length || raw_length > max_name_length { return -1 }
		name_length := int(raw_length)
		if name_length > int(input_length) - position { return -1 }
		record_offsets[i] = position
		record_lengths[i] = name_length
		for j in 0 .. name_length {
			value := unsafe { input[position + j] }
			if value < 65 || value > 90 { return -1 }
		}
		position += name_length
	}
	for i in 0 .. query_count {
		if position >= int(input_length) { return -1 }
		raw_length := unsafe { input[position] }
		position++
		if raw_length < min_name_length || raw_length > max_name_length { return -1 }
		name_length := int(raw_length)
		if name_length > int(input_length) - position { return -1 }
		query_offsets[i] = position
		query_lengths[i] = name_length
		for j in 0 .. name_length {
			value := unsafe { input[position + j] }
			if value < 65 || value > 90 { return -1 }
		}
		position += name_length
	}
	if position != int(input_length) { return -1 }
	if unsafe { output == nil } || output_capacity < usize(query_count) { return -2 }

	for q in 0 .. query_count {
		mut found := -1
		for i in 0 .. record_count {
			if record_lengths[i] != query_lengths[q] { continue }
			mut j := 0
			for j < query_lengths[q] &&
				unsafe { input[record_offsets[i] + j] == input[query_offsets[q] + j] } {
				j++
			}
			if j == query_lengths[q] {
				found = i
				break
			}
		}
		staged[q] = if found < 0 { 255 } else { u8(found) }
	}
	for q in 0 .. query_count {
		unsafe { output[q] = staged[q] }
	}
	i64(query_count)
}
