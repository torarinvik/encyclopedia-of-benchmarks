package weak_heapsort

import "core:c"

MAX_VALUES :: 256
MAX_INPUT_LENGTH :: 258

reverse_offset :: proc(flag: bool) -> int {
	if flag do return 1
	return 0
}

distinguished_ancestor :: proc(reverse: ^[MAX_VALUES]bool, index: int) -> int {
	node := index
	for node > 0 {
		parent := node / 2
		if (node % 2 == 0 && !reverse[parent]) || (node % 2 == 1 && reverse[parent]) {
			node = parent
		} else {
			break
		}
	}
	return node / 2
}

join :: proc(values: ^[MAX_VALUES]i64, reverse: ^[MAX_VALUES]bool, ancestor, node: int) {
	if values[ancestor] < values[node] {
		values[ancestor], values[node] = values[node], values[ancestor]
		reverse[node] = !reverse[node]
	}
}

sift_down :: proc(values: ^[MAX_VALUES]i64, reverse: ^[MAX_VALUES]bool, active_size: int) {
	node := 1
	if reverse[0] do node = 0
	if node >= active_size do return
	for 2*node + reverse_offset(reverse[node]) < active_size {
		node = 2*node + reverse_offset(reverse[node])
	}
	for node != 0 {
		join(values, reverse, 0, node)
		node /= 2
	}
}

@(export)
weak_heapsort :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	count64 := input[0]
	if count64 < 0 || count64 > MAX_VALUES || length != c.size_t(count64 + 1) do return -1
	count := int(count64)
	var values: [MAX_VALUES]i64
	var reverse: [MAX_VALUES]bool
	for index := 0; index < count; index += 1 {
		value := input[index+1]
		if value < -1000 || value > 1000 do return -1
		values[index] = value
	}
	for node := count-1; node > 0; node -= 1 {
		ancestor := distinguished_ancestor(&reverse, node)
		join(&values, &reverse, ancestor, node)
	}
	active_size := count
	for active_size > 1 {
		values[0], values[active_size-1] = values[active_size-1], values[0]
		active_size -= 1
		sift_down(&values, &reverse, active_size)
	}
	checksum: i64 = 0
	for index := 0; index < count; index += 1 {
		checksum += i64(index+1) * (values[index] + 1001)
	}
	return checksum
}
