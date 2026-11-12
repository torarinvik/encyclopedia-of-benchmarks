module hash_join

const max_rows = 8
const hash_capacity = 17
const max_input = 19
const max_output = 64

fn bucket_for(key i64) int {
	mut remainder := key % 17
	if remainder < 0 { remainder += 17 }
	return int(remainder)
}

@[export: 'hash_join']
pub fn hash_join(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_input || unsafe { input == nil } { return -1 }
	left_value := input[0]
	right_value := input[1]
	if left_value < 0 || left_value > max_rows || right_value < 0 || right_value > max_rows { return -1 }
	left_count := int(left_value)
	right_count := int(right_value)
	if int(length) != 2 + left_count + right_count { return -1 }

	build_left := left_count < right_count
	build_count := if build_left { left_count } else { right_count }
	probe_count := if build_left { right_count } else { left_count }
	build_offset := if build_left { 2 } else { 2 + left_count }
	probe_offset := if build_left { 2 + left_count } else { 2 }
	mut keys := [17]i64{}
	mut occupied := [17]bool{}
	mut heads := [17]int{}
	mut tails := [17]int{}
	mut next_row := [8]int{}
	mut staged := [64]u8{}
	for slot in 0 .. hash_capacity {
		heads[slot] = -1
		tails[slot] = -1
	}
	for row in 0 .. max_rows { next_row[row] = -1 }

	unsafe {
		for row in 0 .. build_count {
			key := input[build_offset + row]
			mut slot := bucket_for(key)
			for occupied[slot] && keys[slot] != key { slot = (slot + 1) % hash_capacity }
			if !occupied[slot] { occupied[slot] = true; keys[slot] = key }
			if tails[slot] < 0 { heads[slot] = row }
			else { next_row[tails[slot]] = row }
			tails[slot] = row
		}

		mut match_count := 0
		for probe_row in 0 .. probe_count {
			key := input[probe_offset + probe_row]
			mut slot := bucket_for(key)
			for occupied[slot] && keys[slot] != key { slot = (slot + 1) % hash_capacity }
			if !occupied[slot] { continue }
			mut build_row := heads[slot]
			for build_row >= 0 {
				left_id := if build_left { build_row } else { probe_row }
				right_id := if build_left { probe_row } else { build_row }
				staged[match_count] = u8((left_id << 4) | right_id)
				match_count++
				build_row = next_row[build_row]
			}
		}
		if output_capacity < usize(match_count) || output == nil { return -2 }
		for index in 0 .. match_count { output[index] = staged[index] }
		return i64(match_count)
	}
}
