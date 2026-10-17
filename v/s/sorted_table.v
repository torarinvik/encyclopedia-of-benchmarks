module sorted_table

const max_initial_keys = 128
const max_operations = 256
const max_size = 256
const max_parseable_input_length = 899
const min_key = i64(-1_000_000)
const max_key = i64(1_000_000)
const hash_modulus = i64(1_000_000_007)

fn lower_bound(items []i64, count int, key i64) int {
	mut left, mut right := 0, count
	for left < right {
		middle := left + (right - left) / 2
		if items[middle] < key { left = middle + 1 } else { right = middle }
	}
	return left
}

fn upper_bound(items []i64, count int, key i64) int {
	mut left, mut right := 0, count
	for left < right {
		middle := left + (right - left) / 2
		if items[middle] <= key { left = middle + 1 } else { right = middle }
	}
	return left
}

fn key_code(key i64) i64 { return key - min_key + 1 }

fn sequence_code(items []i64, start int, end int, descending bool) i64 {
	mut hash := i64(0)
	if descending {
		mut index := end - 1
		for index >= start {
			hash = (31 * hash + key_code(items[index])) % hash_modulus
			index--
		}
	} else {
		for index in start .. end { hash = (31 * hash + key_code(items[index])) % hash_modulus }
	}
	return i64(end - start) * hash_modulus + hash
}

@[export: 'sorted_table_benchmark']
pub fn sorted_table_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		initial_value := input[0]
		if initial_value < 0 || initial_value > max_initial_keys { return -1 }
		initial_count := int(initial_value)
		operation_count_index := initial_count + 1
		if usize(operation_count_index) >= length { return -1 }
		operation_value := input[operation_count_index]
		if operation_value < 0 || operation_value > max_operations { return -1 }
		operation_count := int(operation_value)
		if length != usize(operation_count_index + 1 + 3 * operation_count) || length > 898 { return -1 }

		mut items := [max_size]i64{}
		mut count := initial_count
		for index in 0 .. initial_count {
			key := input[index + 1]
			if key < min_key || key > max_key || (index > 0 && items[index - 1] >= key) { return -1 }
			items[index] = key
		}

		mut checksum := i64(0)
		operations_start := operation_count_index + 1
		for operation in 0 .. operation_count {
			position := operations_start + 3 * operation
			opcode, first, second := input[position], input[position + 1], input[position + 2]
			mut observed := i64(0)
			mut has_result := true
			if opcode == 0 || opcode == 1 || opcode == 4 || opcode == 5 || opcode == 7 {
				if second != 0 || first < min_key || first > max_key { return -1 }
				at := lower_bound(items[..], count, first)
				found := at < count && items[at] == first
				if opcode == 0 { if found { observed = key_code(first) }
				} else if opcode == 1 { if found { observed = 1 }
				} else if opcode == 4 {
					next := at
					if found { next++ }
					if next < count { observed = key_code(items[next]) }
				} else if opcode == 5 {
					if at > 0 { observed = key_code(items[at - 1]) }
				} else if found {
					for index := at; index + 1 < count; index++ { items[index] = items[index + 1] }
					count--
					observed = key_code(first)
				}
			} else if opcode == 2 || opcode == 3 {
				if first != 0 || second != 0 { return -1 }
				if count > 0 { if opcode == 2 { observed = key_code(items[0]) } else { observed = key_code(items[count - 1]) } }
			} else if opcode == 6 {
				if first < min_key || first > max_key || (second != 0 && second != 1) { return -1 }
				at := lower_bound(items[..], count, first)
				if at < count && items[at] == first { observed = key_code(items[at])
				} else {
					if count >= max_size { return -1 }
					for index := count; index > at; index-- { items[index] = items[index - 1] }
					items[at] = first
					count++
				}
			} else if opcode == 8 || opcode == 9 {
				if first < min_key || first > max_key || second < min_key || second > max_key { return -1 }
				mut start, mut end := 0, 0
				if first <= second { start = lower_bound(items[..], count, first); end = upper_bound(items[..], count, second) }
				observed = sequence_code(items[..], start, end, opcode == 9)
			} else if opcode == 10 || opcode == 11 {
				if first != 0 || second != 0 { return -1 }
				observed = sequence_code(items[..], 0, count, opcode == 11)
			} else if opcode == 12 {
				if first != 0 || second != 0 { return -1 }
				if count == 0 { observed = 1 }
			} else if opcode == 13 {
				if first != 0 || second != 0 { return -1 }
				count = 0
				has_result = false
			} else { return -1 }
			if has_result { checksum += i64(operation + 1) * (observed + 1) }
		}
		for index in 0 .. count { checksum += i64(operation_count + index + 1) * key_code(items[index]) }
		return checksum
	}
}
