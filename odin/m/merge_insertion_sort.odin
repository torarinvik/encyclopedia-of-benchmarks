package merge_insertion_sort

import "core:c"

MAX_VALUES :: 256
MAX_PAIRS :: MAX_VALUES / 2

sort_pairs :: proc "contextless" (low, high, scratch_low, scratch_high: [^]i64, count: int) {
	width := 1
	for width < count {
		start := 0
		for start < count {
			middle := min(start + width, count)
			end := min(middle + width, count)
			left := start
			right := middle
			output := start
			for left < middle && right < end {
				source := left
				if low[left] > low[right] { source = right; right += 1 } else { left += 1 }
				scratch_low[output] = low[source]
				scratch_high[output] = high[source]
				output += 1
			}
			for left < middle { scratch_low[output] = low[left]; scratch_high[output] = high[left]; left += 1; output += 1 }
			for right < end { scratch_low[output] = low[right]; scratch_high[output] = high[right]; right += 1; output += 1 }
			for index := start; index < end; index += 1 { low[index] = scratch_low[index]; high[index] = scratch_high[index] }
			start += width * 2
		}
		if width > count / 2 { break }
		width *= 2
	}
}

binary_insert :: proc "contextless" (values: [^]i64, length: int, item: i64) -> int {
	low := 0
	high := length
	for low < high {
		middle := low + (high-low)/2
		if values[middle] < item { low = middle+1 } else { high = middle }
	}
	for index := length; index > low; index -= 1 { values[index] = values[index-1] }
	values[low] = item
	return length+1
}

@(export)
merge_insertion_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > c.size_t(MAX_VALUES) { return }
	pair_low: [MAX_PAIRS]i64
	pair_high: [MAX_PAIRS]i64
	scratch_low: [MAX_PAIRS]i64
	scratch_high: [MAX_PAIRS]i64
	chain: [MAX_VALUES]i64
	pair_count := int(length) / 2
	for pair := 0; pair < pair_count; pair += 1 {
		first := values[pair*2]
		second := values[pair*2+1]
		if first <= second { pair_low[pair] = first; pair_high[pair] = second } else { pair_low[pair] = second; pair_high[pair] = first }
	}
	sort_pairs(&pair_low[0], &pair_high[0], &scratch_low[0], &scratch_high[0], pair_count)
	chain_length := 0
	for pair := 0; pair < pair_count; pair += 1 { chain[chain_length] = pair_low[pair]; chain_length += 1 }
	if pair_count > 0 { chain[chain_length] = pair_high[pair_count-1]; chain_length += 1 }
	if int(length) % 2 != 0 { chain_length = binary_insert(&chain[0], chain_length, values[int(length)-1]) }
	for pair := 0; pair+1 < pair_count; pair += 1 { chain_length = binary_insert(&chain[0], chain_length, pair_high[pair]) }
	for index := 0; index < int(length); index += 1 { values[index] = chain[index] }
}
