module main

const max_array_length = 64
const max_input_length = 2 + 2 * max_array_length
const max_parseable_input_length = max_input_length + 1
const min_value = i64(-1_000_000)
const max_value = i64(1_000_000)
const checksum_offset = i64(1_000_001)

@[export: 'merge_sorted']
pub fn merge_sorted(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > max_parseable_input_length {
            return -1
        }
        if input[0] < 0 || input[0] > max_array_length ||
            input[1] < 0 || input[1] > max_array_length {
            return -1
        }

        left_count := int(input[0])
        right_count := int(input[1])
        if int(length) != 2 + left_count + right_count {
            return -1
        }
        right_start := 2 + left_count

        for index in 0 .. left_count {
            value := input[2 + index]
            if value < min_value || value > max_value ||
                (index > 0 && input[2 + index - 1] > value) {
                return -1
            }
        }
        for index in 0 .. right_count {
            value := input[right_start + index]
            if value < min_value || value > max_value ||
                (index > 0 && input[right_start + index - 1] > value) {
                return -1
            }
        }

        mut left_index := 0
        mut right_index := 0
        mut output_index := i64(0)
        mut checksum := i64(0)
        for left_index < left_count && right_index < right_count {
            mut value := i64(0)
            if input[2 + left_index] <= input[right_start + right_index] {
                value = input[2 + left_index]
                left_index++
            } else {
                value = input[right_start + right_index]
                right_index++
            }
            checksum += (output_index + 1) * (value + checksum_offset)
            output_index++
        }
        for left_index < left_count {
            value := input[2 + left_index]
            checksum += (output_index + 1) * (value + checksum_offset)
            left_index++
            output_index++
        }
        for right_index < right_count {
            value := input[right_start + right_index]
            checksum += (output_index + 1) * (value + checksum_offset)
            right_index++
            output_index++
        }
        return checksum
    }
}
