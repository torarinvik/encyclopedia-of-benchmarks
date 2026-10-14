module strand_sort

// Stable strand sort using caller-provided temporary storage.
@[export: 'strand_sort']
pub fn strand_sort(mut values &i64, mut scratch &i64, length usize) {
	if length < 2 {
		return
	}
	unsafe {
		mut remaining := length
		mut result_length := usize(0)
		for remaining > 0 {
			mut strand_length := usize(0)
			mut remaining_write := usize(0)
			for read := usize(0); read < remaining; read++ {
				value := values[read]
				if strand_length == 0 || value >= scratch[strand_length - 1] {
					scratch[strand_length] = value
					strand_length++
				} else {
					values[remaining_write] = value
					remaining_write++
				}
			}
			old_start := length - result_length
			new_start := old_start - strand_length
			for index := usize(0); index < result_length; index++ {
				values[new_start + index] = values[old_start + index]
			}
			mut left := result_length
			mut right := strand_length
			mut destination := length
			for left > 0 && right > 0 {
				if values[new_start + left - 1] > scratch[right - 1] {
					left--
					destination--
					values[destination] = values[new_start + left]
				} else {
					right--
					destination--
					values[destination] = scratch[right]
				}
			}
			for right > 0 {
				right--
				destination--
				values[destination] = scratch[right]
			}
			remaining = remaining_write
			result_length += strand_length
		}
	}
}
