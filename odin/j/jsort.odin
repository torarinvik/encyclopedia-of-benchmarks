package jsort

import "core:c"

sift_down_min :: proc(values: [^]i64, root_value, end: c.size_t) {
	root := root_value
	for root < end / 2 {
		child := root * 2 + 1
		if child + 1 < end && values[child + 1] < values[child] { child += 1 }
		if values[root] <= values[child] { break }
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

sift_down_max :: proc(values: [^]i64, root_value, end: c.size_t) {
	root := root_value
	for root < end / 2 {
		child := root * 2 + 1
		if child + 1 < end && values[child + 1] > values[child] { child += 1 }
		if values[root] >= values[child] { break }
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

reverse_values :: proc(values: [^]i64, length: c.size_t) {
	for left in 0..<length/2 {
		right := length - 1 - left
		temporary := values[left]
		values[left] = values[right]
		values[right] = temporary
	}
}

@(export)
jsort :: proc "c" (values: [^]i64, length: c.size_t) {
	if values == nil || length < 2 do return
	start := length / 2
	for start > 0 {
		start -= 1
		sift_down_min(values, start, length)
	}
	reverse_values(values, length)
	start = length / 2
	for start > 0 {
		start -= 1
		sift_down_max(values, start, length)
	}
	reverse_values(values, length)

	index: c.size_t = 1
	for index < length {
		key := values[index]
		position := index
		for position > 0 && values[position - 1] > key {
			values[position] = values[position - 1]
			position -= 1
		}
		values[position] = key
		index += 1
	}
}
