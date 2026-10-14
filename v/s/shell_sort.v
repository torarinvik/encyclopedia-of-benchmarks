module shell_sort

// Shell sort with a halving gap sequence for the shared contract.
@[export: 'shell_sort']
pub fn shell_sort(mut values &i64, length usize) {
	mut gap := length / 2
	for gap > 0 {
		mut index := gap
		for index < length {
			key := unsafe { values[index] }
			mut position := index
			for position >= gap && unsafe { values[position - gap] } > key {
				unsafe { values[position] = values[position - gap] }
				position -= gap
			}
			unsafe { values[position] = key }
			index++
		}
		gap /= 2
	}
}
