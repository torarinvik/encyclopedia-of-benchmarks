module count_inversions

// Count strict inversions with bottom-up merge sort.
@[export: 'count_inversions']
pub fn count_inversions(values &i64, length usize) i64 {
	max_length := 4096
	if length > max_length { return -1 }
	if length < 2 { return 0 }

	mut source := [4096]i64{}
	mut scratch := [4096]i64{}
	for i := 0; i < int(length); i++ {
		unsafe { source[i] = values[i] }
	}

	mut inversions := i64(0)
	mut width := 1
	for width < int(length) {
		mut low := 0
		for low < int(length) {
			middle := min(low + width, int(length))
			high := min(middle + width, int(length))
			mut left := low
			mut right := middle
			mut output := low
			for left < middle && right < high {
				if source[left] <= source[right] {
					scratch[output] = source[left]
					left++
				} else {
					scratch[output] = source[right]
					right++
					inversions += i64(middle - left)
				}
				output++
			}
			for left < middle {
				scratch[output] = source[left]
				left++
				output++
			}
			for right < high {
				scratch[output] = source[right]
				right++
				output++
			}
			low = high
		}
		for i := 0; i < int(length); i++ { source[i] = scratch[i] }
		width *= 2
	}
	return inversions
}
