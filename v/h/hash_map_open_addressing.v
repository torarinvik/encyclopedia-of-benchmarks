module hash_map_open_addressing

const max_operations = 256
const max_keys = 64
const max_capacity = 1024
const max_input_length = 769
const value_offset = i64(1_000_001)

struct Entry {
mut:
	state int
	key i64
	value i64
}

fn place(mut table [1024]Entry, capacity int, key i64, value i64) {
	mut index := int(key % i64(capacity))
	for _ in 0 .. capacity {
		if table[index].state != 1 { table[index] = Entry{state: 1, key: key, value: value}; return }
		if table[index].key == key { table[index].value = value; return }
		index = (index + 1) % capacity
	}
}

fn resize_table(mut table [1024]Entry, mut capacity int, next int, mut size int) {
	old := table
	old_capacity := capacity
	for i in 0 .. next { table[i] = Entry{} }
	capacity = next
	size = 0
	for i in 0 .. old_capacity {
		if old[i].state == 1 { place(mut table, next, old[i].key, old[i].value); size++ }
	}
}

struct FindResult { found int; tombstone int; tomb_before bool }
fn find_key(table [1024]Entry, capacity int, key i64) FindResult {
	mut index := int(key % i64(capacity))
	mut tombstone := capacity
	for _ in 0 .. capacity {
		if table[index].state == 0 { return FindResult{capacity, tombstone, false} }
		if table[index].state == 2 {
			if tombstone == capacity { tombstone = index }
		} else if table[index].key == key { return FindResult{index, tombstone, tombstone != capacity} }
		index = (index + 1) % capacity
	}
	return FindResult{capacity, tombstone, false}
}

@[export: 'hash_map_open_addressing']
pub fn hash_map_open_addressing(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_input_length { return -1 }
		q := values[0]
		if q < 0 || q > max_operations || length != usize(1 + 3 * q) { return -1 }
		mut table := [1024]Entry{}
		mut capacity := 8
		mut size := 0
		mut query_sum := i64(0)
		mut query_index := i64(0)
		for opi in 0 .. int(q) {
			opcode := values[1 + 3 * opi]
			key := values[2 + 3 * opi]
			value := values[3 + 3 * opi]
			if opcode == 0 {
				if key < 0 || key > 1_000_000 || value < -1_000_000 || value > 1_000_000 { return -1 }
				before := find_key(table, capacity, key)
				if before.found == capacity && size >= max_keys { return -1 }
				if size >= capacity * 3 / 4 {
					if capacity * 2 > max_capacity { return -1 }
					resize_table(mut table, mut capacity, capacity * 2, mut size)
				}
				found := find_key(table, capacity, key)
				if found.found != capacity {
					if found.tomb_before { return -1 }
					table[found.found].value = value
				} else {
					mut index := int(key % i64(capacity))
					mut target := found.tombstone
					for _ in 0 .. capacity {
						if table[index].state == 0 { if target == capacity { target = index }; break }
						index = (index + 1) % capacity
					}
					if target == capacity { return -1 }
					table[target] = Entry{state: 1, key: key, value: value}
					size++
				}
			} else if opcode == 1 || opcode == 2 || opcode == 3 {
				if key < 0 || key > 1_000_000 || value != 0 { return -1 }
				found := find_key(table, capacity, key)
				if (opcode == 1 || opcode == 2) && found.found == capacity { return -1 }
				if opcode == 1 {
					query_index++
					query_sum += query_index * (table[found.found].value + value_offset)
				} else if opcode == 2 {
					table[found.found].state = 2
					size--
					if capacity > 8 && size < capacity * 3 / 8 { resize_table(mut table, mut capacity, capacity / 2, mut size) }
				} else {
					query_index++
					present := i64(0)
					if found.found != capacity { present = 1 }
					query_sum += query_index * (present + value_offset)
				}
			} else if opcode == 4 {
				if key != 0 || value != 0 { return -1 }
				query_index++
				query_sum += query_index * (i64(size) + value_offset)
			} else { return -1 }
		}
		mut keys := [64]i64{}
		mut vals := [64]i64{}
		mut count := 0
		for i in 0 .. capacity {
			if table[i].state == 1 {
				mut at := count
				count++
				for at > 0 && keys[at - 1] > table[i].key { keys[at] = keys[at - 1]; vals[at] = vals[at - 1]; at-- }
				keys[at] = table[i].key
				vals[at] = table[i].value
			}
		}
		mut final_state := i64(0)
		for i in 0 .. count { final_state += i64(i + 1) * (keys[i] + 1) * (vals[i] + value_offset) }
		return query_sum + final_state + i64(size)
	}
}
