package wikisort

import "core:c"

cache_capacity :: c.size_t(512)
run_size :: c.size_t(16)
maximum_length :: c.size_t(2048)

reverse_range :: proc(values: [^]i64, first_value, last_value: c.size_t) {
	first := first_value
	last := last_value
	for first < last {
		last -= 1
		if first >= last {
			break
		}
		item := values[first]
		values[first] = values[last]
		values[last] = item
		first += 1
	}
}

insertion_sort :: proc(values: [^]i64, first, last: c.size_t) {
	for index := first + 1; index < last; index += 1 {
		item := values[index]
		position := index
		for position > first && item < values[position - 1] {
			values[position] = values[position - 1]
			position -= 1
		}
		values[position] = item
	}
}

rotate_adjacent :: proc(values, scratch: [^]i64, first, middle, last, cache_size: c.size_t) {
	left_length := middle - first
	right_length := last - middle
	if left_length == 0 || right_length == 0 {
		return
	}
	if left_length <= right_length && left_length <= cache_size {
		for index := c.size_t(0); index < left_length; index += 1 {
			scratch[index] = values[first + index]
		}
		for index := c.size_t(0); index < right_length; index += 1 {
			values[first + index] = values[middle + index]
		}
		for index := c.size_t(0); index < left_length; index += 1 {
			values[first + right_length + index] = scratch[index]
		}
		return
	}
	if right_length < left_length && right_length <= cache_size {
		for index := c.size_t(0); index < right_length; index += 1 {
			scratch[index] = values[middle + index]
		}
		for index := left_length; index > 0; index -= 1 {
			values[first + right_length + index - 1] = values[first + index - 1]
		}
		for index := c.size_t(0); index < right_length; index += 1 {
			values[first + index] = scratch[index]
		}
		return
	}
	reverse_range(values, first, middle)
	reverse_range(values, middle, last)
	reverse_range(values, first, last)
}

merge_from_cache :: proc(values, scratch: [^]i64, first, middle, last: c.size_t) {
	left_length := middle - first
	for index := c.size_t(0); index < left_length; index += 1 {
		scratch[index] = values[first + index]
	}
	left := c.size_t(0)
	right := middle
	output := first
	for left < left_length && right < last {
		if scratch[left] <= values[right] {
			values[output] = scratch[left]
			left += 1
		} else {
			values[output] = values[right]
			right += 1
		}
		output += 1
	}
	for left < left_length {
		values[output] = scratch[left]
		left += 1
		output += 1
	}
}

block_rotation_merge :: proc(values, scratch: [^]i64, first, middle_value, last, cache_size: c.size_t) {
	total := last - first
	block_size := c.size_t(1)
	for block_size + 1 <= total / (block_size + 1) {
		block_size += 1
	}
	middle := middle_value
	left := first
	for left < middle && middle < last {
		if values[left] <= values[middle] {
			boundary_value := values[middle]
			low := left
			high := middle
			for low < high {
				probe := low + (high - low) / 2
				if values[probe] <= boundary_value {
					low = probe + 1
				} else {
					high = probe
				}
			}
			left = low
		} else {
			key := values[left]
			low := middle
			high := last
			for low < high {
				probe := low + (high - low) / 2
				if values[probe] < key {
					low = probe + 1
				} else {
					high = probe
				}
			}
			block_end := low
			if block_end - middle > block_size {
				block_end = middle + block_size
			}
			moved := block_end - middle
			if moved == 0 {
				left += 1
			} else {
				rotate_adjacent(values, scratch, left, middle, block_end, cache_size)
				left += moved
				middle += moved
			}
		}
	}
}

@(export)
wikisort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if length < 2 || length > maximum_length {
		return
	}
	cache_size := length
	if cache_size > cache_capacity {
		cache_size = cache_capacity
	}
	if length <= 32 {
		insertion_sort(values, 0, length)
		return
	}
	for start := c.size_t(0); start < length; start += run_size {
		end := start + run_size
		if end > length {
			end = length
		}
		insertion_sort(values, start, end)
	}
	width := run_size
	for width < length {
		first := c.size_t(0)
		for first < length {
			middle := first + width
			if middle > length {
				middle = length
			}
			last := middle + width
			if last > length {
				last = length
			}
			if middle < last && values[middle] < values[middle - 1] {
				if values[last - 1] < values[first] {
					rotate_adjacent(values, scratch, first, middle, last, cache_size)
				} else if middle - first <= cache_size {
					merge_from_cache(values, scratch, first, middle, last)
				} else {
					block_rotation_merge(values, scratch, first, middle, last, cache_size)
				}
			}
			first = last
		}
		if width > length / 2 {
			break
		}
		width *= 2
	}
}
