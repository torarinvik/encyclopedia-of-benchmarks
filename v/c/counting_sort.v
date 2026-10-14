module counting_sort

// Counting sort for signed keys in the inclusive range [-128, 128].
@[export: 'counting_sort']
pub fn counting_sort(mut values &i64, mut counts &i64, length usize) {
	unsafe {
		for bucket := usize(0); bucket < 257; bucket++ {
			counts[bucket] = 0
		}
		for index := usize(0); index < length; index++ {
			bucket := usize(values[index] + 128)
			counts[bucket]++
		}
		mut output := usize(0)
		for bucket := usize(0); bucket < 257; bucket++ {
			for counts[bucket] > 0 {
				values[output] = i64(bucket) - 128
				output++
				counts[bucket]--
			}
		}
	}
}
