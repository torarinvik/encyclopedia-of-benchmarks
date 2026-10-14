module bead_sort

// Bead sort for the benchmark's nonnegative 0..63 domain.
@[export: 'bead_sort']
pub fn bead_sort(mut values &i64, mut scratch &i64, length usize) {
	if length < 2 {
		return
	}
	unsafe {
		for level := usize(0); level < 64; level++ {
			scratch[level] = 0
		}
		for index := usize(0); index < length; index++ {
			for level := i64(0); level < values[index]; level++ {
				scratch[usize(level)]++
			}
		}
		for index := usize(0); index < length; index++ {
			row_from_bottom := length - 1 - index
			mut value := i64(0)
			for level := usize(0); level < 64; level++ {
				if scratch[level] > i64(row_from_bottom) {
					value++
				}
			}
			values[index] = value
		}
	}
}
