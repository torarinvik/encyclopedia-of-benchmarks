module wikisort

const cache_capacity = usize(512)
const run_size = usize(16)
const maximum_length = usize(2048)

fn reverse_range(mut values &i64, first_value usize, last_value usize) {
	mut first := first_value
	mut last := last_value
	for first < last {
		last--
		if first >= last {
			break
		}
		unsafe {
			item := values[first]
			values[first] = values[last]
			values[last] = item
		}
		first++
	}
}

fn insertion_sort(mut values &i64, first usize, last usize) {
	for index := first + 1; index < last; index++ {
		mut item := i64(0)
		unsafe { item = values[index] }
		mut position := index
		for position > first {
			mut previous := i64(0)
			unsafe { previous = values[position - 1] }
			if item >= previous {
				break
			}
			unsafe { values[position] = previous }
			position--
		}
		unsafe { values[position] = item }
	}
}

fn rotate_adjacent(mut values &i64, mut scratch &i64, first usize, middle usize, last usize, cache_size usize) {
	left_length := middle - first
	right_length := last - middle
	if left_length == 0 || right_length == 0 {
		return
	}
	if left_length <= right_length && left_length <= cache_size {
		for index := usize(0); index < left_length; index++ {
			unsafe { scratch[index] = values[first + index] }
		}
		for index := usize(0); index < right_length; index++ {
			unsafe { values[first + index] = values[middle + index] }
		}
		for index := usize(0); index < left_length; index++ {
			unsafe { values[first + right_length + index] = scratch[index] }
		}
		return
	}
	if right_length < left_length && right_length <= cache_size {
		for index := usize(0); index < right_length; index++ {
			unsafe { scratch[index] = values[middle + index] }
		}
		mut index := left_length
		for index > 0 {
			index--
			unsafe { values[first + right_length + index] = values[first + index] }
		}
		for index := usize(0); index < right_length; index++ {
			unsafe { values[first + index] = scratch[index] }
		}
		return
	}
	reverse_range(mut values, first, middle)
	reverse_range(mut values, middle, last)
	reverse_range(mut values, first, last)
}

fn merge_from_cache(mut values &i64, mut scratch &i64, first usize, middle usize, last usize) {
	left_length := middle - first
	for index := usize(0); index < left_length; index++ {
		unsafe { scratch[index] = values[first + index] }
	}
	mut left := usize(0)
	mut right := middle
	mut output := first
	for left < left_length && right < last {
		mut a := i64(0)
		mut b := i64(0)
		unsafe {
			a = scratch[left]
			b = values[right]
		}
		if a <= b {
			unsafe { values[output] = a }
			left++
		} else {
			unsafe { values[output] = b }
			right++
		}
		output++
	}
	for left < left_length {
		unsafe { values[output] = scratch[left] }
		left++
		output++
	}
}

fn block_rotation_merge(mut values &i64, mut scratch &i64, first usize, middle_value usize, last usize, cache_size usize) {
	total := last - first
	mut block_size := usize(1)
	for block_size + 1 <= total / (block_size + 1) {
		block_size++
	}
	mut middle := middle_value
	mut left := first
	for left < middle && middle < last {
		mut left_value := i64(0)
		mut right_value := i64(0)
		unsafe {
			left_value = values[left]
			right_value = values[middle]
		}
		if left_value <= right_value {
			boundary_value := right_value
			mut low := left
			mut high := middle
			for low < high {
				probe := low + (high - low) / 2
				mut value := i64(0)
				unsafe { value = values[probe] }
				if value <= boundary_value {
					low = probe + 1
				} else {
					high = probe
				}
			}
			left = low
		} else {
			key := left_value
			mut low := middle
			mut high := last
			for low < high {
				probe := low + (high - low) / 2
				mut value := i64(0)
				unsafe { value = values[probe] }
				if value < key {
					low = probe + 1
				} else {
					high = probe
				}
			}
			mut block_end := low
			if block_end - middle > block_size {
				block_end = middle + block_size
			}
			moved := block_end - middle
			if moved == 0 {
				left++
			} else {
				rotate_adjacent(mut values, mut scratch, left, middle, block_end, cache_size)
				left += moved
				middle += moved
			}
		}
	}
}

@[export: 'wikisort']
pub fn wikisort(mut values &i64, mut scratch &i64, length usize) {
	if length < 2 || length > maximum_length {
		return
	}
	cache_size := if length < cache_capacity { length } else { cache_capacity }
	if length <= 32 {
		insertion_sort(mut values, 0, length)
		return
	}
	for start := usize(0); start < length; start += run_size {
		end := if start + run_size < length { start + run_size } else { length }
		insertion_sort(mut values, start, end)
	}
	mut width := run_size
	for width < length {
		mut first := usize(0)
		for first < length {
			middle := if first + width < length { first + width } else { length }
			last := if middle + width < length { middle + width } else { length }
			if middle < last {
				mut right_value := i64(0)
				mut left_value := i64(0)
				unsafe {
					right_value = values[middle]
					left_value = values[middle - 1]
				}
				if right_value < left_value {
					mut last_value := i64(0)
					mut first_value := i64(0)
					unsafe {
						last_value = values[last - 1]
						first_value = values[first]
					}
					if last_value < first_value {
						rotate_adjacent(mut values, mut scratch, first, middle, last, cache_size)
					} else if middle - first <= cache_size {
						merge_from_cache(mut values, mut scratch, first, middle, last)
					} else {
						block_rotation_merge(mut values, mut scratch, first, middle, last, cache_size)
					}
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
