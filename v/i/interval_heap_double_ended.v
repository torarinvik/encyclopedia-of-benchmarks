module interval_heap_double_ended

import core:c

const max_initial = 64
const max_operations = 128
const max_keys = max_initial + max_operations
const max_input = max_initial + 2 + 2 * max_operations

struct IntervalHeap {
mut:
	keys [max_keys]i32
	count int
}

fn high_index(heap &IntervalHeap, node int) int {
	high := 2 * node + 1
	return if high < heap.count { high } else { 2 * node }
}

fn sift_up_low(mut heap IntervalHeap, start int) {
	mut node := start
	for node > 0 {
		parent := (node - 1) / 2
		low := 2 * node
		parent_low := 2 * parent
		if heap.keys[low] >= heap.keys[parent_low] { return }
		heap.keys[low], heap.keys[parent_low] = heap.keys[parent_low], heap.keys[low]
		node = parent
	}
}

fn sift_up_high(mut heap IntervalHeap, start int) {
	mut node := start
	for node > 0 {
		parent := (node - 1) / 2
		high := high_index(heap, node)
		parent_high := high_index(heap, parent)
		if heap.keys[high] <= heap.keys[parent_high] { return }
		heap.keys[high], heap.keys[parent_high] = heap.keys[parent_high], heap.keys[high]
		node = parent
	}
}

fn insert_key(mut heap IntervalHeap, value i32) {
	key_index := heap.count
	heap.keys[key_index] = value
	heap.count++
	node := key_index / 2
	if key_index % 2 == 1 && heap.keys[key_index] < heap.keys[key_index - 1] {
		heap.keys[key_index], heap.keys[key_index - 1] = heap.keys[key_index - 1], heap.keys[key_index]
	}
	sift_up_low(mut heap, node)
	sift_up_high(mut heap, node)
}

fn extract_min(mut heap IntervalHeap) i32 {
	result := heap.keys[0]
	heap.count--
	last := heap.keys[heap.count]
	if heap.count == 0 { return result }
	heap.keys[0] = last
	mut node := 0
	for {
		left := 2 * node + 1
		if 2 * left >= heap.count { return result }
		right := left + 1
		mut child := left
		if 2 * right < heap.count && heap.keys[2 * right] < heap.keys[2 * left] { child = right }
		node_low := 2 * node
		child_low := 2 * child
		if heap.keys[child_low] >= heap.keys[node_low] { return result }
		heap.keys[node_low], heap.keys[child_low] = heap.keys[child_low], heap.keys[node_low]
		child_high := high_index(heap, child)
		if heap.keys[child_high] < heap.keys[child_low] {
			heap.keys[child_high], heap.keys[child_low] = heap.keys[child_low], heap.keys[child_high]
		}
		node = child
	}
}

fn extract_max(mut heap IntervalHeap) i32 {
	if heap.count <= 2 {
		heap.count--
		return heap.keys[heap.count]
	}
	result := heap.keys[1]
	heap.count--
	heap.keys[1] = heap.keys[heap.count]
	mut node := 0
	for {
		left := 2 * node + 1
		if 2 * left >= heap.count { return result }
		right := left + 1
		mut child := left
		if 2 * right < heap.count && heap.keys[high_index(heap, left)] < heap.keys[high_index(heap, right)] { child = right }
		node_high := high_index(heap, node)
		child_high := high_index(heap, child)
		if heap.keys[node_high] >= heap.keys[child_high] { return result }
		heap.keys[node_high], heap.keys[child_high] = heap.keys[child_high], heap.keys[node_high]
		child_low := 2 * child
		if heap.keys[child_high] < heap.keys[child_low] {
			heap.keys[child_high], heap.keys[child_low] = heap.keys[child_low], heap.keys[child_high]
		}
		node = child
	}
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

fn sort_i32(mut values [max_keys]i32, count int) {
	for index in 1 .. count {
		value := values[index]
		mut position := index
		for position > 0 && values[position - 1] > value {
			values[position] = values[position - 1]
			position--
		}
		values[position] = value
	}
}

@[export: 'interval_heap_double_ended']
pub fn interval_heap_double_ended(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input) { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_initial { return -1 }
		initial_count := int(input[0])
		if length < usize(initial_count + 2) || input[initial_count + 1] < 0 || input[initial_count + 1] > max_operations { return -1 }
		operation_count := int(input[initial_count + 1])
		if length != usize(initial_count + 2 + 2 * operation_count) { return -1 }
		for index in 0 .. initial_count {
			if input[index + 1] < -2_147_483_648 || input[index + 1] > 2_147_483_647 { return -1 }
		}
		for op in 0 .. operation_count {
			opcode := input[initial_count + 2 + 2 * op]
			argument := input[initial_count + 3 + 2 * op]
			if opcode < 0 || opcode > 5 { return -1 }
			if opcode == 0 {
				if argument < -2_147_483_648 || argument > 2_147_483_647 { return -1 }
			} else if argument != 0 { return -1 }
		}
		mut heap := IntervalHeap{}
		for index in 0 .. initial_count { insert_key(mut heap, i32(input[index + 1])) }
		mut events := [max_operations]i64{}
		mut event_count := 0
		for op in 0 .. operation_count {
			opcode := input[initial_count + 2 + 2 * op]
			argument := i32(input[initial_count + 3 + 2 * op])
			if opcode == 0 { insert_key(mut heap, argument) }
			else if opcode == 1 {
				if heap.count == 0 { return -1 }
				events[event_count] = i64(heap.keys[0]); event_count++
			} else if opcode == 2 {
				if heap.count == 0 { return -1 }
				events[event_count] = i64(heap.keys[high_index(heap, 0)]); event_count++
			} else if opcode == 3 {
				if heap.count == 0 { return -1 }
				events[event_count] = i64(extract_min(mut heap)); event_count++
			} else if opcode == 4 {
				if heap.count == 0 { return -1 }
				events[event_count] = i64(extract_max(mut heap)); event_count++
			} else { events[event_count] = i64(heap.count); event_count++ }
		}
		mut sorted := heap.keys
		sort_i32(mut sorted, heap.count)
		required := (2 + event_count + heap.count) * 8
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		offset := 0
		write_i64_le(mut output, offset, i64(event_count)); offset += 8
		for index in 0 .. event_count { write_i64_le(mut output, offset, events[index]); offset += 8 }
		write_i64_le(mut output, offset, i64(heap.count)); offset += 8
		for index in 0 .. heap.count { write_i64_le(mut output, offset, i64(sorted[index])); offset += 8 }
		return i64(required)
	}
}
