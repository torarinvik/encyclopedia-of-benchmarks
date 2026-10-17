module sliding_window_aggregator

const max_capacity = 64
const max_count = 256
const max_parseable_input_length = 259

@[export: 'sliding_window_aggregator']
pub fn sliding_window_aggregator(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_parseable_input_length) { return i64(-9223372036854775807 - 1) }
	unsafe {
		capacity_value, count_value := input[0], input[1]
		if capacity_value < 1 || capacity_value > max_capacity || count_value < 1 || count_value > max_count { return i64(-9223372036854775807 - 1) }
		capacity, count := int(capacity_value), int(count_value)
		if length != usize(count + 2) { return i64(-9223372036854775807 - 1) }
		mut window := [max_capacity]i64{}
		mut head, mut size := 0, 0
		mut sum := i64(0)
		for index in 0 .. count {
			value := input[index + 2]
			if value < -1_000_000 || value > 1_000_000 { return i64(-9223372036854775807 - 1) }
			if size < capacity {
				position := (head + size) % capacity
				window[position] = value
				size++
				sum += value
			} else {
				sum -= window[head]
				window[head] = value
				sum += value
				head = (head + 1) % capacity
			}
		}
		return sum
	}
}
