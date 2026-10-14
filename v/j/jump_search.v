module jump_search

fn integer_sqrt(value usize) usize {
	if value < 2 {
		return value
	}
	mut low := usize(1)
	mut high := value / 2 + 1
	mut result := usize(1)
	for low <= high {
		middle := low + (high - low) / 2
		if middle <= value / middle {
			result = middle
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return result
}

// Jump search in an ascending sequence for the shared benchmark contract.
@[export: 'jump_search']
pub fn jump_search(values &i64, length usize, target i64) i64 {
	if length == 0 {
		return -1
	}
	step := integer_sqrt(length)
	mut block_start := usize(0)
	mut block_end := if step < length { step } else { length }
	for unsafe { values[block_end - 1] } < target {
		if block_end == length {
			return -1
		}
		block_start = block_end
		block_end = if step > length - block_end { length } else { block_end + step }
	}
	for index := block_start; index < block_end; index++ {
		value := unsafe { values[index] }
		if value == target {
			return i64(index)
		}
		if value > target {
			return -1
		}
	}
	return -1
}
