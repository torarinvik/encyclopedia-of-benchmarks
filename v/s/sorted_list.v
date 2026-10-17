module sorted_list

const max_operations = 512
const max_collection_size = 256
const max_parseable_input_length = 1025

fn search_position(values []i64, count int, target i64) (int, bool) {
	mut left, mut right := 0, count
	for right > left {
		middle := (left + right) / 2
		if target > values[middle] { left = middle + 1 }
		else if target < values[middle] { right = middle }
		else { return middle, true }
	}
	return left, false
}

@[export: 'sorted_list_benchmark']
pub fn sorted_list_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } {
		if length == 0 { return 0 }
		return -1
	}
	if length > usize(max_parseable_input_length) || length % 2 != 0 { return -1 }
	unsafe {
		operation_count := int(length / 2)
		if operation_count > max_operations { return -1 }
		mut values := [max_collection_size]i64{}
		mut count := 0
		mut checksum := i64(0)
		for operation in 0 .. operation_count {
			opcode, payload := input[2 * operation], input[2 * operation + 1]
			if opcode < 0 || opcode > 5 { return -1 }
			if opcode == 0 {
				if payload < 0 || payload > 1_000_000 || count >= max_collection_size { return -1 }
				position, _ := search_position(values[..], count, payload)
				for index := count; index > position; index-- { values[index] = values[index - 1] }
				values[position] = payload
				count++
			} else if opcode == 1 || opcode == 2 {
				if payload < 0 || payload > 1_000_000 { return -1 }
				position, found := search_position(values[..], count, payload)
				observed := if found { i64(1) } else { i64(0) }
				if opcode == 2 && found {
					for index := position; index + 1 < count; index++ { values[index] = values[index + 1] }
					count--
				}
				checksum += i64(operation + 1) * (observed + 1_000_000)
			} else if opcode == 3 {
				if payload != 0 { return -1 }
				checksum += i64(operation + 1) * (i64(count) + 1_000_000)
			} else if opcode == 4 {
				if payload < 0 || payload >= i64(count) { return -1 }
				checksum += i64(operation + 1) * (values[int(payload)] + 1_000_000)
			} else {
				if payload != 0 { return -1 }
				count = 0
			}
		}
		for index in 0 .. count { checksum += i64(operation_count + index + 1) * (values[index] + 1_000_000) }
		return checksum
	}
}
