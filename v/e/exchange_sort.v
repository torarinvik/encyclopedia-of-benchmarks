module exchange_sort

// In-place exchange sort for the shared sorting contract.
@[export: 'exchange_sort']
pub fn exchange_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	last := length - 1
	mut first := usize(0)
	for first < last {
		mut other := first + 1
		for other < length {
			if unsafe { values[other] } < unsafe { values[first] } {
				temporary := unsafe { values[first] }
				unsafe {
					values[first] = values[other]
					values[other] = temporary
				}
			}
			other++
		}
		first++
	}
}
