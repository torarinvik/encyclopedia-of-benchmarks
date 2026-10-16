module second_min_max

const invalid_result = i64(-9223372036854775807 - 1)
const max_input_length = 259
const int32_min_value = i64(-2147483648)
const int32_max_value = i64(2147483647)

@[export: 'second_min_max']
pub fn second_min_max(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return invalid_result }
	unsafe {
		operation, raw_count := input[0], input[1]
		if (operation != 0 && operation != 1) || raw_count < 2 || raw_count > 256 { return invalid_result }
		count := int(raw_count)
		if length != usize(count + 2) { return invalid_result }
		initial := if operation == 0 { int32_max_value } else { int32_min_value }
		mut best, mut second := initial, initial
		for index in 0 .. count {
			value := input[index + 2]
			if value < int32_min_value || value > int32_max_value { return invalid_result }
			better := if operation == 0 { value < best } else { value > best }
			if better {
				second = best
				best = value
			} else {
				improves_second := if operation == 0 { value < second } else { value > second }
				if improves_second && value != best { second = value }
			}
		}
		if second == initial { return invalid_result }
		return second
	}
}
