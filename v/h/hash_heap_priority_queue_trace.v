module hash_heap_priority_queue_trace

const max_ops = 64
const max_buckets = 8

struct Item {
	key u8
	insertion u8
}

fn before(a Item, b Item) bool {
	return a.key < b.key || (a.key == b.key && a.insertion < b.insertion)
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'hash_heap_priority_queue_trace']
pub fn hash_heap_priority_queue_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 132 { return -1 }
	unsafe {
		universe_value := input[0]
		bucket_value := input[1]
		count_value := input[2]
		if universe_value < 1 || universe_value > 128 || bucket_value < 1 || bucket_value > 8 ||
			bucket_value > universe_value || count_value < 0 || count_value > max_ops { return -1 }
		universe := int(universe_value)
		bucket_count := int(bucket_value)
		count := int(count_value)
		if length != usize(3 + 2 * count) { return -1 }
		mut ops := [max_ops]u8{}
		mut args := [max_ops]u8{}
		for op in 0 .. count {
			opcode := input[3 + 2 * op]
			argument := input[4 + 2 * op]
			if opcode == 0 {
				if argument < 0 || argument >= universe_value { return -1 }
			} else if opcode == 1 || opcode == 2 {
				if argument != 0 { return -1 }
			} else { return -1 }
			ops[op] = u8(opcode)
			args[op] = u8(argument)
		}
		mut heaps := [max_buckets][max_ops]Item{}
		mut sizes := [max_buckets]int{}
		mut words := [max_ops + 1]i64{}
		words[0] = i64(count)
		for op in 0 .. count {
			if ops[op] == 0 {
				bucket := int(args[op]) * bucket_count / universe
				mut child := sizes[bucket]
				sizes[bucket]++
				heaps[bucket][child] = Item{key: args[op], insertion: u8(op)}
				for child > 0 {
					parent := (child - 1) / 2
					if !before(heaps[bucket][child], heaps[bucket][parent]) { break }
					heaps[bucket][child], heaps[bucket][parent] = heaps[bucket][parent], heaps[bucket][child]
					child = parent
				}
				words[op + 1] = -2
				continue
			}
			mut bucket := 0
			for bucket < bucket_count && sizes[bucket] == 0 { bucket++ }
			if bucket == bucket_count { words[op + 1] = -1; continue }
			item := heaps[bucket][0]
			words[op + 1] = (i64(item.insertion) << 8) | i64(item.key)
			if ops[op] == 2 {
				sizes[bucket]--
				last := sizes[bucket]
				if last > 0 {
					heaps[bucket][0] = heaps[bucket][last]
					mut parent := 0
					for {
						left := 2 * parent + 1
						if left >= sizes[bucket] { break }
						mut child := left
						right := left + 1
						if right < sizes[bucket] && before(heaps[bucket][right], heaps[bucket][left]) { child = right }
						if !before(heaps[bucket][child], heaps[bucket][parent]) { break }
						heaps[bucket][child], heaps[bucket][parent] = heaps[bucket][parent], heaps[bucket][child]
						parent = child
					}
				}
			}
		}
		required := (count + 1) * 8
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		mut staged := [520]u8{}
		for index in 0 .. count + 1 { write_i64_le(mut staged[0], index * 8, words[index]) }
		for byte in 0 .. required { output[byte] = staged[byte] }
		return i64(required)
	}
}
