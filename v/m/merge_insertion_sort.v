module merge_insertion_sort

fn sort_pairs(mut low &i64, mut high &i64, mut scratch_low &i64, mut scratch_high &i64, count usize) {
	mut width := usize(1)
	for width < count {
		mut start := usize(0)
		for start < count {
			mut middle := start + width
			if middle > count { middle = count }
			mut end_index := middle + width
			if end_index > count { end_index = count }
			mut left := start
			mut right := middle
			mut output := start
			for left < middle && right < end_index {
				if unsafe { low[left] <= low[right] } {
					unsafe { scratch_low[output] = low[left]; scratch_high[output] = high[left] }
					left++
				} else {
					unsafe { scratch_low[output] = low[right]; scratch_high[output] = high[right] }
					right++
				}
				output++
			}
			for left < middle {
				unsafe { scratch_low[output] = low[left]; scratch_high[output] = high[left] }
				left++; output++
			}
			for right < end_index {
				unsafe { scratch_low[output] = low[right]; scratch_high[output] = high[right] }
				right++; output++
			}
			for index in start .. end_index {
				unsafe { low[index] = scratch_low[index]; high[index] = scratch_high[index] }
			}
			start += width * 2
		}
		if width > count / 2 { break }
		width *= 2
	}
}

fn binary_insert(mut values &i64, length usize, item i64) usize {
	mut low := usize(0)
	mut high := length
	for low < high {
		middle := low + (high - low) / 2
		if unsafe { values[middle] < item } { low = middle + 1 } else { high = middle }
	}
	for index := length; index > low; index-- { unsafe { values[index] = values[index - 1] } }
	unsafe { values[low] = item }
	return length + 1
}

@[export: 'merge_insertion_sort']
pub fn merge_insertion_sort(mut values &i64, length usize) {
	if length > 256 { return }
	mut pair_low := [128]i64{}
	mut pair_high := [128]i64{}
	mut scratch_low := [128]i64{}
	mut scratch_high := [128]i64{}
	mut chain := [256]i64{}
	pair_count := length / 2
	for pair in usize(0) .. pair_count {
		first := unsafe { values[pair * 2] }
		second := unsafe { values[pair * 2 + 1] }
		if first <= second { pair_low[pair] = first; pair_high[pair] = second } else { pair_low[pair] = second; pair_high[pair] = first }
	}
	sort_pairs(mut pair_low[0], mut pair_high[0], mut scratch_low[0], mut scratch_high[0], pair_count)
	mut chain_length := usize(0)
	for pair in usize(0) .. pair_count { chain[chain_length] = pair_low[pair]; chain_length++ }
	if pair_count > 0 { chain[chain_length] = pair_high[pair_count - 1]; chain_length++ }
	if length % 2 != 0 { chain_length = binary_insert(mut chain[0], chain_length, unsafe { values[length - 1] }) }
	mut pair := usize(0)
	for pair + 1 < pair_count {
		chain_length = binary_insert(mut chain[0], chain_length, pair_high[pair])
		pair++
	}
	for index in usize(0) .. length { unsafe { values[index] = chain[index] } }
}
