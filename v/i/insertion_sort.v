module insertion_sort

// Stable insertion sort for the shared mutable in-place sorting contract.
@[export: 'insertion_sort']
pub fn insertion_sort(mut values &i64, length usize) {
	if length < 2 {
		return
	}
	mut index := usize(1)
	for index < length {
		key := unsafe { values[index] }
		mut position := index
		for position > 0 && unsafe { values[position - 1] } > key {
			unsafe { values[position] = values[position - 1] }
			position--
		}
		unsafe { values[position] = key }
		index++
	}
}
