module shell_sort2

@[export: 'shell_sort2']
pub fn shell_sort2(mut values &i64, length usize) {
	mut gaps := [8]usize{}
	gaps[0] = 701; gaps[1] = 301; gaps[2] = 132; gaps[3] = 57
	gaps[4] = 23; gaps[5] = 10; gaps[6] = 4; gaps[7] = 1
	for gap in gaps {
		mut index := gap
		for index < length {
			key := unsafe { values[index] }
			mut position := index
			for position >= gap && unsafe { values[position - gap] > key } {
				unsafe { values[position] = values[position - gap] }
				position -= gap
			}
			unsafe { values[position] = key }
			index++
		}
	}
}
