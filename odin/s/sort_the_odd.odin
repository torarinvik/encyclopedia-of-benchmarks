package sort_the_odd

MAX_LENGTH :: 256
MIN_VALUE :: i64(-1_000_000)
MAX_VALUE :: i64(1_000_000)
CHECKSUM_OFFSET :: i64(1_000_001)

sift_down :: proc(values: [^]i64, start, end: int) {
	root := start
	for root * 2 + 1 < end {
		child := root * 2 + 1
		if child + 1 < end && values[child] < values[child + 1] {
			child += 1
		}
		if values[root] >= values[child] {
			break
		}
		values[root], values[child] = values[child], values[root]
		root = child
	}
}

heap_sort :: proc(values: [^]i64, length: int) {
	start := length / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, length)
	}
	end := length
	for end > 1 {
		end -= 1
		values[0], values[end] = values[end], values[0]
		sift_down(values, 0, end)
	}
}

@(export)
sort_the_odd_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (input == nil && length != 0) do return -1

	odds: [MAX_LENGTH]i64
	odd_count := 0
	for i in 0..<int(length) {
		value := input[i]
		if value < MIN_VALUE || value > MAX_VALUE do return -1
		if value % 2 != 0 {
			odds[odd_count] = value
			odd_count += 1
		}
	}
	if odd_count > 1 do heap_sort(&odds[0], odd_count)

	odd_index := 0
	checksum := i64(0)
	for i in 0..<int(length) {
		value := input[i]
		if value % 2 != 0 {
			value = odds[odd_index]
			odd_index += 1
		}
		checksum += i64(i + 1) * (value + CHECKSUM_OFFSET)
	}
	return checksum
}
