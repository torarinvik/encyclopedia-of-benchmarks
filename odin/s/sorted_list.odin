package sorted_list

import "core:c"

MAX_OPERATIONS :: 512
MAX_COLLECTION_SIZE :: 256
MAX_VALID_INPUT_LENGTH :: c.size_t(1024)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(1025)

search_position :: proc "contextless" (values: [^]i64, count: int, target: i64) -> (int, bool) {
	left, right := 0, count
	for right-left > 0 {
		middle := (left + right) / 2
		if target > values[middle] { left = middle + 1
		} else if target < values[middle] { right = middle
		} else { return middle, true }
	}
	return left, false
}

sorted_list_benchmark :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil {
		if length == 0 { return 0 }
		return -1
	}
	if length > MAX_PARSEABLE_INPUT_LENGTH || length % 2 != 0 do return -1
	if length > MAX_VALID_INPUT_LENGTH do return -1
	operation_count := int(length / 2)
	if operation_count > MAX_OPERATIONS do return -1
	var values: [MAX_COLLECTION_SIZE]i64
	count := 0
	checksum := i64(0)
	for operation in 0 ..< operation_count {
		opcode, payload := input[2*operation], input[2*operation+1]
		if opcode < 0 || opcode > 5 do return -1
		if opcode == 0 {
			if payload < 0 || payload > 1_000_000 || count >= MAX_COLLECTION_SIZE do return -1
			position, _ := search_position(&values[0], count, payload)
			for index := count; index > position; index -= 1 { values[index] = values[index-1] }
			values[position] = payload
			count += 1
		} else if opcode == 1 || opcode == 2 {
			if payload < 0 || payload > 1_000_000 do return -1
			position, found := search_position(&values[0], count, payload)
			observed := i64(0)
			if found { observed = 1 }
			if opcode == 2 && found {
				for index := position; index+1 < count; index += 1 { values[index] = values[index+1] }
				count -= 1
			}
			checksum += i64(operation+1) * (observed + 1_000_000)
		} else if opcode == 3 {
			if payload != 0 do return -1
			checksum += i64(operation+1) * (i64(count) + 1_000_000)
		} else if opcode == 4 {
			if payload < 0 || payload >= i64(count) do return -1
			checksum += i64(operation+1) * (values[int(payload)] + 1_000_000)
		} else {
			if payload != 0 do return -1
			count = 0
		}
	}
	for index in 0 ..< count { checksum += i64(operation_count+index+1) * (values[index] + 1_000_000) }
	return checksum
}
