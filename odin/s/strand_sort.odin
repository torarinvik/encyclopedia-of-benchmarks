package strand_sort

import "core:c"

@(export)
strand_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	remaining := length
	result_length := c.size_t(0)
	for remaining > 0 {
		strand_length := c.size_t(0)
		remaining_write := c.size_t(0)
		for read := c.size_t(0); read < remaining; read += 1 {
			value := values[read]
			if strand_length == 0 || value >= scratch[strand_length - 1] {
				scratch[strand_length] = value
				strand_length += 1
			} else {
				values[remaining_write] = value
				remaining_write += 1
			}
		}
		old_start := length - result_length
		new_start := old_start - strand_length
		for index := c.size_t(0); index < result_length; index += 1 {
			values[new_start + index] = values[old_start + index]
		}
		left := result_length
		right := strand_length
		destination := length
		for left > 0 && right > 0 {
			if values[new_start + left - 1] > scratch[right - 1] {
				left -= 1
				destination -= 1
				values[destination] = values[new_start + left]
			} else {
				right -= 1
				destination -= 1
				values[destination] = scratch[right]
			}
		}
		for right > 0 {
			right -= 1
			destination -= 1
			values[destination] = scratch[right]
		}
		remaining = remaining_write
		result_length += strand_length
	}
}
