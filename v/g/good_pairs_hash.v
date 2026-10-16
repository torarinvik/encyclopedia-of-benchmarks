module good_pairs_hash

// Count equal-value index pairs with a bounded open-addressed frequency table.
const table_size = 512

@[export: 'good_pairs_hash']
pub fn good_pairs_hash(input &i64, length usize) i64 {
	if length < 1 || length > 258 || unsafe { input == nil } { return -1 }
	declared := unsafe { input[0] }
	if declared < 0 || declared > 256 || length != usize(declared + 1) { return -1 }
	n := int(declared)
	mut keys := [512]i64{}
	mut frequencies := [512]u64{}
	mut occupied := [512]bool{}
	for index in 0 .. n {
		value := unsafe { input[index + 1] }
		if value < -1000000 || value > 1000000 { return -1 }
		mut slot := int(((value + 1000000) * 2654435761) % 512)
		for occupied[slot] && keys[slot] != value { slot = (slot + 1) % 512 }
		if !occupied[slot] { occupied[slot] = true; keys[slot] = value }
		frequencies[slot]++
	}
	mut pairs := u64(0)
	for frequency in frequencies {
		if frequency > 1 { pairs += frequency * (frequency - 1) / 2 }
	}
	return i64(pairs)
}
