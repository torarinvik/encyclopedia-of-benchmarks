module pigeonhole_sort

// Portable pigeonhole sort for signed keys in [-128, 128].
@[export: 'pigeonhole_sort']
pub fn pigeonhole_sort(mut values &i64, mut scratch &i64, length usize) {
	if length < 2 {
		return
	}
	unsafe {
		for bucket := usize(0); bucket < 257; bucket++ {
			scratch[bucket] = 0
		}
		for index := usize(0); index < length; index++ {
			bucket := usize(values[index] + 128)
			scratch[bucket]++
		}
		mut index := usize(0)
		for bucket := usize(0); bucket < 257; bucket++ {
			for scratch[bucket] > 0 {
				values[index] = i64(bucket) - 128
				index++
				scratch[bucket]--
			}
		}
	}
}
