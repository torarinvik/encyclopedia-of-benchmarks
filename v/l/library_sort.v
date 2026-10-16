module library_sort

const max_items = 256
const i32_max = i64(2147483647)

fn find_insertion_index(data []i64, occupied []bool, capacity int, value i64) int {
	mut low := 0
	mut high := capacity
	for low < high {
		middle := low + (high - low) / 2
		mut probe := i32_max
		for index := middle; index < capacity; index++ {
			if occupied[index] {
				probe = data[index]
				break
			}
		}
		if probe != i32_max && probe <= value { low = middle + 1 }
		else { high = middle }
	}
	return low
}

fn insert_at_end(mut data []i64, mut occupied []bool, capacity int, value i64) {
	last := capacity - 1
	mut left := last - 1
	for left >= 0 && occupied[left] { left-- }
	if left < 0 { return }
	for index := left; index < last; index++ { data[index] = data[index + 1] }
	occupied[left] = true
	data[last] = value
}

fn insert_value(mut data []i64, mut occupied []bool, capacity int, value i64) {
	position := find_insertion_index(data, occupied, capacity, value)
	if position >= capacity { insert_at_end(mut data, mut occupied, capacity, value); return }
	if !occupied[position] { data[position] = value; occupied[position] = true; return }

	mut right := position
	for right < capacity && occupied[right] { right++ }
	mut left := position - 1
	for left >= 0 && occupied[left] { left-- }
	can_go_right := right < capacity
	can_go_left := left >= 0
	if can_go_right && (!can_go_left || right - position <= position - left) {
		mut index := right
		for index > position { data[index] = data[index - 1]; index-- }
		occupied[right] = true
		data[position] = value
	} else if can_go_left {
		gap := left
		for index := gap; index + 1 < position; index++ { data[index] = data[index + 1] }
		occupied[gap] = true
		data[position - 1] = value
	}
}

// Bounded port of the pinned Java Library Sort gap-insertion routine.
@[export: 'library_sort']
pub fn library_sort(mut values &i64, length usize) {
	if unsafe { values == nil } || length < 2 || length > max_items { return }
	capacity := int(length) * 2
	mut data := []i64{len: capacity, init: 0}
	mut temporary := []i64{len: int(length), init: 0}
	mut occupied := []bool{len: capacity, init: false}
	mut filled := 1
	mut next := 1
	mut round := 0
	middle := capacity / 2
	unsafe { data[middle] = values[0] }
	occupied[middle] = true

	for next < int(length) {
		mut batch := 1 << round
		if batch > int(length) - next { batch = int(length) - next }
		for index := 0; index < batch; index++ {
			unsafe { insert_value(mut data, mut occupied, capacity, values[next + index]) }
			filled++
		}
		next += batch
		round++
		if next < int(length) {
			mut at := 0
			for index := 0; index < capacity; index++ {
				if occupied[index] { temporary[at] = data[index]; at++ }
			}
			for index := 0; index < capacity; index++ { occupied[index] = false }
			for index := 0; index < filled; index++ {
				slot := index * capacity / filled
				data[slot] = temporary[index]
				occupied[slot] = true
			}
		}
	}

	mut output := 0
	for index := 0; index < capacity; index++ {
		if occupied[index] {
			unsafe { values[output] = data[index] }
			output++
		}
	}
}
