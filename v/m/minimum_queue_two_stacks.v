const queue_capacity = 16
const max_parseable_length = 65
const value_min = i64(-1000)
const value_max = i64(1000)
const checksum_offset = i64(1001)

@[export: 'minimum_queue_two_stacks']
pub fn minimum_queue_two_stacks(input &i64, length usize) i64 {
	if length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		if input == nil || input[0] < 0 || input[0] > 32 { return -1 }
		mut in_values := [queue_capacity]i64{}
		mut in_minimums := [queue_capacity]i64{}
		mut out_values := [queue_capacity]i64{}
		mut out_minimums := [queue_capacity]i64{}
		mut in_count := 0
		mut out_count := 0
		mut cursor := 1
		operation_count := int(input[0])
		mut checksum := i64(0)

		for operation in 0 .. operation_count {
			if cursor >= length { return -1 }
			opcode := input[cursor]
			cursor++
			if opcode == 0 {
				if cursor >= length { return -1 }
				value := input[cursor]
				cursor++
				if value < value_min || value > value_max || in_count + out_count >= queue_capacity { return -1 }
				in_values[in_count] = value
				if in_count == 0 || value < in_minimums[in_count - 1] {
					in_minimums[in_count] = value
				} else {
					in_minimums[in_count] = in_minimums[in_count - 1]
				}
				in_count++
			} else if opcode == 1 {
				if in_count + out_count == 0 { return -1 }
				if out_count == 0 {
					for in_count > 0 {
						in_count--
						value := in_values[in_count]
						out_values[out_count] = value
						if out_count == 0 || value < out_minimums[out_count - 1] {
							out_minimums[out_count] = value
						} else {
							out_minimums[out_count] = out_minimums[out_count - 1]
						}
						out_count++
					}
				}
				out_count--
				checksum += i64(operation + 1) * (out_values[out_count] + checksum_offset)
			} else if opcode == 2 {
				if in_count + out_count == 0 { return -1 }
				mut observed := i64(0)
				if in_count == 0 {
					observed = out_minimums[out_count - 1]
				} else if out_count == 0 {
					observed = in_minimums[in_count - 1]
				} else if in_minimums[in_count - 1] < out_minimums[out_count - 1] {
					observed = in_minimums[in_count - 1]
				} else {
					observed = out_minimums[out_count - 1]
				}
				checksum += i64(operation + 1) * (observed + checksum_offset)
			} else {
				return -1
			}
		}
		if cursor != length { return -1 }

		mut position := 0
		for index in 0 .. out_count {
			position++
			checksum += i64(position) * (out_values[out_count - index - 1] + checksum_offset)
		}
		for index in 0 .. in_count {
			position++
			checksum += i64(position) * (in_values[index] + checksum_offset)
		}
		return checksum
	}
}
