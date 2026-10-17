module priority_queues

const max_capacity = 128
const max_operations = 256
const max_input_values = 515
const max_output_bytes = 4096

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'priority_queues']
pub fn priority_queues(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values {
		return -1
	}
	unsafe {
		capacity_value := input[0]
		operation_count_value := input[1]
		if capacity_value < 1 || capacity_value > max_capacity ||
			operation_count_value < 0 || operation_count_value > max_operations {
			return -1
		}
		capacity := int(capacity_value)
		operation_count := int(operation_count_value)
		if int(length) != 2 + 2 * operation_count {
			return -1
		}
		for operation in 0 .. operation_count {
			opcode := input[2 + 2 * operation]
			argument := input[3 + 2 * operation]
			if opcode < 0 || opcode > 5 {
				return -1
			}
			if opcode == 0 {
				if argument < -2147483648 || argument > 2147483647 {
					return -1
				}
			} else if argument != 0 {
				return -1
			}
		}

		if operation_count == 0 {
			return 0
		}
		needed := operation_count * 16
		if needed > max_output_bytes || output == nil ||
			output_capacity < usize(needed) {
			return -2
		}

		mut heap := [max_capacity + 1]i32{}
		mut size := 0
		for operation in 0 .. operation_count {
			opcode := input[2 + 2 * operation]
			argument := input[3 + 2 * operation]
			mut status := i64(0)
			mut value := i64(0)

			if opcode == 0 {
				if size == capacity {
					status = 1
				} else {
					size++
					heap[size] = i32(argument)
					mut index := size
					for index > 1 && heap[index / 2] < heap[index] {
						temporary := heap[index / 2]
						heap[index / 2] = heap[index]
						heap[index] = temporary
						index /= 2
					}
				}
			} else if opcode == 1 {
				if size == 0 {
					status = 2
				} else {
					value = i64(heap[1])
					heap[1] = heap[size]
					heap[size] = 0
					size--
					mut index := 1
					for index * 2 <= size {
						mut child := index * 2
						if child < size && heap[child + 1] > heap[child] {
							child++
						}
						if heap[index] >= heap[child] {
							break
						}
						temporary := heap[index]
						heap[index] = heap[child]
						heap[child] = temporary
						index = child
					}
				}
			} else if opcode == 2 {
				if size > 0 {
					value = i64(heap[1])
				}
			} else if opcode == 3 {
				if size == 0 {
					value = 1
				}
			} else if opcode == 4 {
				if size == capacity {
					value = 1
				}
			} else {
				value = i64(size)
			}

			store_i64_le(output, operation * 16, status)
			store_i64_le(output, operation * 16 + 8, value)
		}
		return i64(needed)
	}
}
