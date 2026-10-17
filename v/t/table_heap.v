module table_heap

const max_items = 64
const max_ops = 256
const nil_value = i64(-9223372036854775808)

struct Entry { priority i32; index int }

fn heapify_down(mut heap [64]i32, mut entries map[i32]Entry, count int, start int, update bool) {
	mut index := start
	for {
		left := index * 2 + 1
		if left >= count { return }
		mut child := left + 1
		if child >= count || entries[heap[left]].priority < entries[heap[child]].priority { child = left }
		if entries[heap[child]].priority >= entries[heap[index]].priority { return }
		heap[index], heap[child] = heap[child], heap[index]
		if update { entries[heap[index]] = Entry{entries[heap[index]].priority, index}; entries[heap[child]] = Entry{entries[heap[child]].priority, child} }
		index = child
	}
}
fn heapify_up(mut heap [64]i32, mut entries map[i32]Entry, start int) {
	mut index := start
	for index > 0 {
		parent := (index - 1) / 2
		if entries[heap[index]].priority >= entries[heap[parent]].priority { return }
		heap[index], heap[parent] = heap[parent], heap[index]
		entries[heap[index]] = Entry{entries[heap[index]].priority, index}
		entries[heap[parent]] = Entry{entries[heap[parent]].priority, parent}
		index = parent
	}
}
fn store_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> u64(8 * byte)) & 255) } }
}

@[export: 'table_heap']
pub fn table_heap(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 1155 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_items { return -1 }
		initial := int(input[0]); op_index := 1 + 2 * initial
		if length <= usize(op_index) || input[op_index] < 0 || input[op_index] > max_ops { return -1 }
		op_count := int(input[op_index])
		if length != usize(2 + 2 * initial + 4 * op_count) || length > 1154 { return -1 }
		mut heap := [64]i32{}
		mut entries := map[i32]Entry{}
		for i in 0 .. initial {
			id := input[1 + 2 * i]; priority := input[2 + 2 * i]
			if id < -2147483648 || id > 2147483647 || priority < -2147483648 || priority > 2147483647 { return -1 }
			item := i32(id); if item in entries { return -1 }
			heap[i] = item; entries[item] = Entry{i32(priority), 0}
		}
		mut parent := initial / 2
		for parent > 0 { parent--; heapify_down(mut heap, mut entries, initial, parent, false) }
		for i in 0 .. initial { entries[heap[i]] = Entry{entries[heap[i]].priority, i} }
		mut count := initial
		mut answers := [256]i64{}
		mut cursor := op_index + 1
		for oi in 0 .. op_count {
			op := input[cursor]; a := input[cursor + 1]; b := input[cursor + 2]; c := input[cursor + 3]; cursor += 4
			if op < 0 || op > 9 { return -1 }
			if op == 0 {
				if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 || c != 0 || count == max_items { return -1 }
				item := i32(a); if item in entries { return -1 }
				heap[count] = item; entries[item] = Entry{i32(b), count}; count++; heapify_up(mut heap, mut entries, count - 1); answers[oi] = nil_value
			} else if op == 1 {
				if a != 0 || b != 0 || c != 0 { return -1 }; answers[oi] = if count == 0 { nil_value } else { i64(heap[0]) }
			} else if op == 2 {
				if a != 0 || b != 0 || c != 0 || count == 0 { return -1 }
				removed := heap[0]; answers[oi] = i64(removed); heap[0], heap[count - 1] = heap[count - 1], heap[0]
				entries[heap[0]] = Entry{entries[heap[0]].priority, 0}; entries[heap[count - 1]] = Entry{entries[heap[count - 1]].priority, count - 1}; count--; entries.delete(removed)
				if count > 0 { heapify_down(mut heap, mut entries, count, 0, true) }
			} else if op == 3 || op == 4 {
				if a != 0 || b != 0 || c != 0 { return -1 }; answers[oi] = if op == 3 { i64(count) } else if count == 0 { 1 } else { 0 }
			} else if op == 5 {
				if a < -2147483648 || a > 2147483647 || b != 0 || c != 0 { return -1 }
				id := i32(a); answers[oi] = if id in entries { i64(entries[id].index + 1) } else { nil_value }
			} else if op == 6 || op == 7 {
				if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 || c != 0 { return -1 }
				id := i32(a); if id !in entries { return -1 }; old := entries[id].priority
				if (op == 6 && b > i64(old)) || (op == 7 && b < i64(old)) { return -1 }
				position := entries[id].index; entries[id] = Entry{i32(b), position}
				if op == 6 { heapify_up(mut heap, mut entries, position) } else { heapify_down(mut heap, mut entries, count, position, true) }; answers[oi] = nil_value
			} else if op == 8 {
				if a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647 || c < -2147483648 || c > 2147483647 { return -1 }
				old_id := i32(a); new_id := i32(b); if old_id !in entries { return -1 }; old := entries[old_id]
				if new_id in entries { if new_id != old_id || c != i64(old.priority) { return -1 } }
				else { entries.delete(old_id); heap[old.index] = new_id; entries[new_id] = Entry{i32(c), old.index}; if i32(c) < old.priority { heapify_up(mut heap, mut entries, old.index) } else { heapify_down(mut heap, mut entries, count, old.index, true) } }
				answers[oi] = nil_value
			} else {
				if a < -2147483648 || a > 2147483647 || b != 0 || c != 0 { return -1 }
				id := i32(a); if id !in entries { return -1 }; removed := entries[id]; count--
				if removed.index != count { heap[removed.index] = heap[count]; entries[heap[removed.index]] = Entry{entries[heap[removed.index]].priority, removed.index}; if entries[heap[removed.index]].priority < removed.priority { heapify_up(mut heap, mut entries, removed.index) } else { heapify_down(mut heap, mut entries, count, removed.index, true) } }
				entries.delete(id); answers[oi] = nil_value
			}
		}
		output_bytes := op_count * 8
		if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
		for i in 0 .. op_count { store_i64(mut output, i * 8, answers[i]) }
		return i64(output_bytes)
	}
}
