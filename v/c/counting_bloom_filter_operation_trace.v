module counting_bloom_filter_operation_trace

const max_operations = 64
const max_parseable_length = 130
const counter_count = 67
const hash_count = 4

fn hash_positions(key i64) [hash_count]int {
	first := (17 * key + 3) % counter_count
	stride := 1 + ((5 * key + 3) % (counter_count - 1))
	mut positions := [hash_count]int{}
	for j in 0 .. hash_count {
		positions[j] = int((first + i64(j) * stride) % counter_count)
	}
	return positions
}

@[export: 'counting_bloom_filter_operation_trace']
pub fn counting_bloom_filter_operation_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length { return -1 }
		raw_count := input[0]
		if raw_count < 0 || raw_count > max_operations { return -1 }
		count := int(raw_count)
		if length != usize(1 + 2 * count) { return -1 }
		for operation in 0 .. count {
			opcode := input[1 + 2 * operation]
			key := input[2 + 2 * operation]
			if opcode < 0 || opcode > 2 || key < 0 || key > 65535 { return -1 }
		}
		if output == nil || capacity < usize(count) { return -2 }

		mut counters := [counter_count]u8{}
		mut statuses := [max_operations]u8{}
		for operation in 0 .. count {
			opcode := input[1 + 2 * operation]
			key := input[2 + 2 * operation]
			positions := hash_positions(key)
			if opcode == 0 {
				for position in positions { counters[position]++ }
				statuses[operation] = 1
			} else if opcode == 1 {
				// The input contract guarantees that each deleted key is live.
				for position in positions { counters[position]-- }
				statuses[operation] = 1
			} else {
				mut present := true
				for position in positions {
					if counters[position] == 0 { present = false }
				}
				statuses[operation] = if present { 1 } else { 0 }
			}
		}
		for operation in 0 .. count { output[operation] = statuses[operation] }
		return i64(count)
	}
}
