module circular_buffer

const max_capacity = 256
const value_offset = i64(1_000_000)

// Bounded circular buffer with overwrite-oldest behavior when full.
@[export: 'circular_buffer_benchmark']
pub fn circular_buffer_benchmark(values &i64, length usize) i64 {
	if length < 1 || length > 1025 || (length - 1) % 2 != 0 { return -1 }
	capacity_value := unsafe { values[0] }
	if capacity_value < 1 || capacity_value > max_capacity { return -1 }
	capacity := int(capacity_value)
	operation_count := int((length - 1) / 2)
	mut buffer := [max_capacity]i64{init: 0}
	mut head := 0
	mut tail := 0
	mut count := 0
	mut checksum := i64(0)
	for operation in 0 .. operation_count {
		opcode := unsafe { values[1 + 2 * operation] }
		payload := unsafe { values[2 + 2 * operation] }
		mut observed := i64(0)
		if opcode == 0 {
			if payload < 0 || payload > value_offset { return -1 }
			if count == 0 { observed = 1 }
			if count == capacity { head = (head + 1) % capacity } else { count++ }
			buffer[tail] = payload
			tail = (tail + 1) % capacity
		} else if opcode == 1 {
			if payload != 0 { return -1 }
			if count == 0 { observed = -1 } else {
				observed = buffer[head]
				head = (head + 1) % capacity
				count--
			}
		} else if opcode == 2 {
			if payload != 0 { return -1 }
			if count == 0 { observed = 1 }
		} else if opcode == 3 {
			if payload != 0 { return -1 }
			if count == capacity { observed = 1 }
		} else if opcode == 4 {
			if payload != 0 { return -1 }
			observed = i64(count)
		} else { return -1 }
		checksum += i64(operation + 1) * (observed + value_offset)
	}
	for index in 0 .. count {
		checksum += i64(operation_count + index + 1) * (buffer[(head + index) % capacity] + value_offset)
	}
	return checksum
}
