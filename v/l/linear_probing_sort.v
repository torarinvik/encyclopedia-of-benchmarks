module linear_probing_sort

fn insertion_sort(mut values &i64, length usize) {
	for index := usize(1); index < length; index++ {
		key := unsafe { values[index] }
		mut position := index
		for position > 0 {
			previous := unsafe { values[position - 1] }
			if previous <= key { break }
			unsafe { values[position] = previous }
			position--
		}
		unsafe { values[position] = key }
	}
}

@[export: 'linear_probing_sort']
pub fn linear_probing_sort(mut values &i64, length usize) {
	if values == nil || length < 2 { return }
	if length > 1024 {
		insertion_sort(mut values, length)
		return
	}

	mut minimum := unsafe { values[0] }
	mut maximum := minimum
	for index := usize(0); index < length; index++ {
		value := unsafe { values[index] }
		if value < 0 || value > 255 {
			insertion_sort(mut values, length)
			return
		}
		if value < minimum { minimum = value }
		if value > maximum { maximum = value }
	}

	main_slots := usize(256) * (length + 1) + 1
	table_length := main_slots + length
	mut table := []i64{len: int(table_length), init: 0}
	defer { unsafe { table.free() } }
	span := maximum - minimum
	for index := usize(0); index < length; index++ {
		value := unsafe { values[index] }
		mut home := usize(0)
		if span != 0 {
			home = usize((value - minimum) * i64(main_slots - 1) / span)
		}
		mut slot := home
		for table[int(slot)] != 0 { slot++ }
		table[int(slot)] = value + 1
	}
	mut output := usize(0)
	for slot := usize(0); slot < table_length; slot++ {
		if table[int(slot)] != 0 {
			unsafe { values[output] = table[int(slot)] - 1 }
			output++
		}
	}
}
