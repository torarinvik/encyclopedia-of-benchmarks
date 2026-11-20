module cuckoo_filter_operation_trace

const buckets = 8
const width = 4
const max_operations = 32
const max_kicks = 8

fn delta(fingerprint i64) int {
	return 1 + ((5 * int(fingerprint) + 3) % 7)
}

fn first_empty(table [buckets * width]i64, bucket int) int {
	for slot in 0 .. width {
		if table[bucket * width + slot] == 0 { return slot }
	}
	return width
}

fn insert(mut table [buckets * width]i64, primary int, fingerprint i64) bool {
	alternate := primary ^ delta(fingerprint)
	mut empty := first_empty(table, primary)
	if empty < width { table[primary * width + empty] = fingerprint; return true }
	empty = first_empty(table, alternate)
	if empty < width { table[alternate * width + empty] = fingerprint; return true }
	mut current := primary
	mut pending := fingerprint
	for _ in 0 .. max_kicks {
		position := current * width
		evicted := table[position]
		table[position] = pending
		pending = evicted
		current ^= delta(pending)
		empty = first_empty(table, current)
		if empty < width { table[current * width + empty] = pending; return true }
	}
	return false
}

fn write_i64_le(mut output &u8, index int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[index * 8 + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'cuckoo_filter_operation_trace']
pub fn cuckoo_filter_operation_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 98 { return -1 }
		raw_count := input[0]
		if raw_count < 1 || raw_count > max_operations { return -1 }
		count := int(raw_count)
		if length != usize(1 + 3 * count) { return -1 }
		for operation in 0 .. count {
			opcode := input[1 + 3 * operation]
			primary := input[2 + 3 * operation]
			fingerprint := input[3 + 3 * operation]
			if opcode < 0 || opcode > 2 || primary < 0 || primary >= buckets || fingerprint < 1 || fingerprint > 15 { return -1 }
		}
		required := count * 8
		if output == nil || capacity < usize(required) { return -2 }
		mut table := [buckets * width]i64{init: 0}
		mut statuses := [max_operations]i64{init: 0}
		for operation in 0 .. count {
			opcode := input[1 + 3 * operation]
			primary := int(input[2 + 3 * operation])
			fingerprint := input[3 + 3 * operation]
			alternate := primary ^ delta(fingerprint)
			if opcode == 0 {
				if !insert(mut table, primary, fingerprint) { return -3 }
				statuses[operation] = 1
			} else if opcode == 1 {
				mut found := false
				for order in 0 .. 2 {
					bucket := if order == 0 { primary } else { alternate }
					for slot in 0 .. width { if table[bucket * width + slot] == fingerprint { found = true } }
				}
				statuses[operation] = if found { 1 } else { 0 }
			} else {
				mut removed := false
				for order in 0 .. 2 {
					if removed { break }
					bucket := if order == 0 { primary } else { alternate }
					for slot in 0 .. width {
						position := bucket * width + slot
						if table[position] == fingerprint { table[position] = 0; removed = true; break }
					}
				}
				statuses[operation] = if removed { 1 } else { 0 }
			}
		}
		for operation in 0 .. count { write_i64_le(mut output, operation, statuses[operation]) }
		return i64(required)
	}
}
