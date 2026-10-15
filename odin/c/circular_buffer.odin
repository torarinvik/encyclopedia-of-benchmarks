package circular_buffer

import "core:c"

MAX_CAPACITY :: 256
VALUE_OFFSET :: i64(1_000_000)

@(export)
circular_buffer_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 1025 || (length - 1) % 2 != 0 do return -1
	capacity_value := values[0]
	if capacity_value < 1 || capacity_value > MAX_CAPACITY do return -1
	capacity := int(capacity_value)
	operation_count := int((length - 1) / 2)
	buffer: [MAX_CAPACITY]i64
	head, tail, count := 0, 0, 0
	checksum := i64(0)
	for operation := 0; operation < operation_count; operation += 1 {
		opcode, payload := values[1 + 2 * operation], values[2 + 2 * operation]
		observed := i64(0)
		if opcode == 0 {
			if payload < 0 || payload > VALUE_OFFSET do return -1
			if count == 0 do observed = 1
			if count == capacity { head = (head + 1) % capacity } else { count += 1 }
			buffer[tail] = payload
			tail = (tail + 1) % capacity
		} else if opcode == 1 {
			if payload != 0 do return -1
			if count == 0 { observed = -1 } else {
				observed = buffer[head]
				head = (head + 1) % capacity
				count -= 1
			}
		} else if opcode == 2 {
			if payload != 0 do return -1
			if count == 0 do observed = 1
		} else if opcode == 3 {
			if payload != 0 do return -1
			if count == capacity do observed = 1
		} else if opcode == 4 {
			if payload != 0 do return -1
			observed = i64(count)
		} else do return -1
		checksum += i64(operation + 1) * (observed + VALUE_OFFSET)
	}
	for index := 0; index < count; index += 1 {
		checksum += i64(operation_count + index + 1) * (buffer[(head + index) % capacity] + VALUE_OFFSET)
	}
	return checksum
}
