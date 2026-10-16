package library_sort

import "core:c"

MAX_ITEMS :: 256
MAX_CAPACITY :: 2 * MAX_ITEMS
I32_MAX :: i64 = 2_147_483_647

find_insertion_index :: proc(data: ^[MAX_CAPACITY]i64, occupied: ^[MAX_CAPACITY]bool,
                             capacity: int, value: i64) -> int {
	low := 0
	high := capacity
	for low < high {
		middle := low + (high - low) / 2
		probe := I32_MAX
		for index := middle; index < capacity; index += 1 {
			if occupied[index] { probe = data[index]; break }
		}
		if probe != I32_MAX && probe <= value { low = middle + 1 }
		else { high = middle }
	}
	return low
}

insert_at_end :: proc(data: ^[MAX_CAPACITY]i64, occupied: ^[MAX_CAPACITY]bool,
                      capacity: int, value: i64) {
	last := capacity - 1
	left := last - 1
	for left >= 0 && occupied[left] { left -= 1 }
	if left < 0 { return }
	for index := left; index < last; index += 1 { data[index] = data[index + 1] }
	occupied[left] = true
	data[last] = value
}

insert_value :: proc(data: ^[MAX_CAPACITY]i64, occupied: ^[MAX_CAPACITY]bool,
                     capacity: int, value: i64) {
	position := find_insertion_index(data, occupied, capacity, value)
	if position >= capacity { insert_at_end(data, occupied, capacity, value); return }
	if !occupied[position] { data[position] = value; occupied[position] = true; return }

	right := position
	for right < capacity && occupied[right] { right += 1 }
	left := position - 1
	for left >= 0 && occupied[left] { left -= 1 }
	can_go_right := right < capacity
	can_go_left := left >= 0
	if can_go_right && (!can_go_left || right - position <= position - left) {
		index := right
		for index > position { data[index] = data[index - 1]; index -= 1 }
		occupied[right] = true
		data[position] = value
	} else if can_go_left {
		gap := left
		for index := gap; index + 1 < position; index += 1 { data[index] = data[index + 1] }
		occupied[gap] = true
		data[position - 1] = value
	}
}

@(export)
library_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if values == nil || length < 2 || length > MAX_ITEMS { return }
	n := int(length)
	capacity := 2 * n
	data: [MAX_CAPACITY]i64
	temporary: [MAX_ITEMS]i64
	occupied: [MAX_CAPACITY]bool = {}
	filled := 1
	next := 1
	round := 0
	middle := capacity / 2
	data[middle] = values[0]
	occupied[middle] = true

	for next < n {
		batch := 1 << round
		if batch > n - next { batch = n - next }
		for index := 0; index < batch; index += 1 {
			insert_value(&data, &occupied, capacity, values[next + index])
			filled += 1
		}
		next += batch
		round += 1
		if next < n {
			at := 0
			for index := 0; index < capacity; index += 1 {
				if occupied[index] { temporary[at] = data[index]; at += 1 }
			}
			for index := 0; index < capacity; index += 1 { occupied[index] = false }
			for index := 0; index < filled; index += 1 {
				slot := index * capacity / filled
				data[slot] = temporary[index]
				occupied[slot] = true
			}
		}
	}

	output := 0
	for index := 0; index < capacity; index += 1 {
		if occupied[index] { values[output] = data[index]; output += 1 }
	}
}
