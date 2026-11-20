module elias_fano_monotone_sequence

const max_values = 32
const max_high_bits = 96
const max_input_length = 35

@[export: 'elias_fano_monotone_sequence']
pub fn elias_fano_monotone_sequence(input &i64, length usize) i64 {
	if input == nil || length < 3 || length > max_input_length { return -1 }
	unsafe {
		count_value, upper := input[0], input[1]
		if count_value < 1 || count_value > max_values || upper < 0 || upper > 1_000_000 { return -1 }
		count := int(count_value)
		if count_value > upper + 1 || length != usize(count + 2) { return -1 }

		mut source := [max_values]i64{}
		for index in 0 .. count {
			value := input[index + 2]
			if value < 0 || value > upper || (index > 0 && value < source[index - 1]) { return -1 }
			source[index] = value
		}

		mut low_width := 0
		mut low_power := i64(1)
		for i64(count) * low_power * 2 <= upper + 1 {
			low_power *= 2
			low_width++
		}
		low_mask := low_power - 1
		mut low_parts := [max_values]i64{}
		mut high_bits := [max_high_bits]bool{}
		high_length := int(upper / low_power) + count
		if high_length > max_high_bits { return -1 }
		for index in 0 .. count {
			low_parts[index] = source[index] & low_mask
			position := int(source[index] / low_power) + index
			if position < 0 || position >= high_length { return -1 }
			high_bits[position] = true
		}

		mut checksum := i64(0)
		mut item_index := 0
		for position in 0 .. high_length {
			if high_bits[position] {
				if item_index >= count || position < item_index { return -1 }
				high_part := position - item_index
				decoded := (i64(high_part) << low_width) | low_parts[item_index]
				checksum += i64(item_index + 1) * decoded
				item_index++
			}
		}
		if item_index != count { return -1 }
		return checksum
	}
}
