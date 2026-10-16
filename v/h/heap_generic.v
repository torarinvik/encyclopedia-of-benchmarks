module heap_generic

const max_operations = 512
const max_items = 128
const id_capacity = 4096
const max_input_length = 1537
const fnv_offset = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)

fn hash_byte(hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn hash_i32(hash_value u64, value i64) u64 {
	mut hash := hash_value
	bits := u32(i32(value))
	for shift in 0 .. 4 {
		hash = hash_byte(hash, u8((bits >> (shift * 8)) & 255))
	}
	return hash
}

fn swap_items(mut ids [128]i64, mut priorities [128]i64, mut positions [4096]int, first int, second int) {
	ids[first], ids[second] = ids[second], ids[first]
	priorities[first], priorities[second] = priorities[second], priorities[first]
	positions[int(ids[first])] = first
	positions[int(ids[second])] = second
}

fn heapify_up(mut ids [128]i64, mut priorities [128]i64, mut positions [4096]int, start int) {
	mut index := start
	for index > 0 {
		parent := (index - 1) / 2
		if priorities[index] <= priorities[parent] { break }
		swap_items(mut ids, mut priorities, mut positions, index, parent)
		index = parent
	}
}

fn heapify_down(mut ids [128]i64, mut priorities [128]i64, mut positions [4096]int,
	heap_size int, start int) {
	mut index := start
	for {
		mut best := index
		left := 2 * index + 1
		right := left + 1
		if left < heap_size && priorities[left] > priorities[best] { best = left }
		if right < heap_size && priorities[right] > priorities[best] { best = right }
		if best == index { return }
		swap_items(mut ids, mut priorities, mut positions, index, best)
		index = best
	}
}

fn erase_item(mut ids [128]i64, mut priorities [128]i64, mut positions [4096]int,
	mut heap_size int, item_id int) {
	index := positions[item_id]
	last := heap_size - 1
	positions[item_id] = -1
	if index != last {
		ids[index] = ids[last]
		priorities[index] = priorities[last]
		positions[int(ids[index])] = index
	}
	heap_size = last
	if index < heap_size {
		heapify_up(mut ids, mut priorities, mut positions, index)
		heapify_down(mut ids, mut priorities, mut positions, heap_size, index)
	}
}

@[export: 'heap_generic']
pub fn heap_generic(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > usize(max_input_length) { return -1 }
		operation_count_value := values[0]
		if operation_count_value < 0 || operation_count_value > max_operations ||
			length != usize(1 + 3 * operation_count_value) { return -1 }

		mut ids := [128]i64{}
		mut priorities := [128]i64{}
		mut positions := [4096]int{}
		mut used_ids := [4096]bool{}
		for index in 0 .. id_capacity { positions[index] = -1 }
		mut heap_size := 0
		mut hash := fnv_offset

		for operation := 0; operation < int(operation_count_value); operation++ {
			opcode := values[1 + 3 * operation]
			item_id := values[2 + 3 * operation]
			priority := values[3 + 3 * operation]
			mut present := false
			mut returned_id := i64(0)
			mut returned_priority := i64(0)

			if opcode == 0 {
				if item_id < 0 || item_id >= id_capacity || priority < -2147483648 || priority > 2147483647 ||
					used_ids[int(item_id)] || heap_size >= max_items { return -1 }
				for index in 0 .. heap_size { if priorities[index] == priority { return -1 } }
				used_ids[int(item_id)] = true
				ids[heap_size] = item_id
				priorities[heap_size] = priority
				positions[int(item_id)] = heap_size
				heap_size++
				heapify_up(mut ids, mut priorities, mut positions, heap_size - 1)
			} else if opcode == 1 || opcode == 2 {
				if item_id != 0 || priority != 0 { return -1 }
				if heap_size > 0 {
					present = true
					returned_id = ids[0]
					returned_priority = priorities[0]
					if opcode == 2 { erase_item(mut ids, mut priorities, mut positions, mut heap_size, int(returned_id)) }
				}
			} else if opcode == 3 {
				if item_id < 0 || item_id >= id_capacity || priority < -2147483648 || priority > 2147483647 ||
					positions[int(item_id)] < 0 { return -1 }
				index := positions[int(item_id)]
				for other in 0 .. heap_size {
					if other != index && priorities[other] == priority { return -1 }
				}
				priorities[index] = priority
				heapify_up(mut ids, mut priorities, mut positions, index)
				heapify_down(mut ids, mut priorities, mut positions, heap_size, index)
			} else if opcode == 4 {
				if item_id < 0 || item_id >= id_capacity || priority != 0 || positions[int(item_id)] < 0 { return -1 }
				erase_item(mut ids, mut priorities, mut positions, mut heap_size, int(item_id))
			} else { return -1 }

			hash = hash_byte(hash, u8(opcode))
			hash = hash_byte(hash, if present { u8(1) } else { u8(0) })
			if present {
				hash = hash_i32(hash, returned_id)
				hash = hash_i32(hash, returned_priority)
			}
		}
		return i64(hash)
	}
}
