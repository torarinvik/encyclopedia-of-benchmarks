module quick_select

const max_values = 1024

fn median_of_three(first i64, middle i64, last i64) i64 {
	if first < middle {
		if middle < last { return middle }
		if first < last { return last }
		return first
	}
	if first < last { return first }
	if middle < last { return last }
	return middle
}

@[export: 'quick_select']
pub fn quick_select(values &i64, length usize) i64 {
	if length == 0 || length > max_values { return -1 }
	mut scratch := [1024]i64{}
	for index in 0 .. length {
		scratch[index] = unsafe { values[index] }
	}
	target := length / 2
	mut low := usize(0)
	mut high := length
	for high - low > 1 {
		middle := low + (high - low) / 2
		pivot := median_of_three(scratch[low], scratch[middle], scratch[high - 1])
		mut less := low
		mut scan := low
		mut greater := high
		for scan < greater {
			if scratch[scan] < pivot {
				temporary := scratch[less]
				scratch[less] = scratch[scan]
				scratch[scan] = temporary
				less++
				scan++
			} else if scratch[scan] > pivot {
				greater--
				temporary := scratch[greater]
				scratch[greater] = scratch[scan]
				scratch[scan] = temporary
			} else {
				scan++
			}
		}
		if target < less { high = less }
		else if target >= greater { low = greater }
		else { return pivot }
	}
	return scratch[target]
}
