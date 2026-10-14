module bingo_sort

@[export: 'bingo_sort']
pub fn bingo_sort(mut values &i64, length usize) {
	if length > 1024 || length < 2 { return }
	mut bingo := unsafe { values[0] }
	for index in usize(1) .. length {
		if unsafe { values[index] < bingo } { bingo = unsafe { values[index] } }
	}
	mut next_position := usize(0)
	for next_position < length {
		mut has_next := false
		mut next_bingo := i64(0)
		mut index := next_position
		for index < length {
			current := unsafe { values[index] }
			if current == bingo {
				temporary := unsafe { values[next_position] }
				unsafe { values[next_position] = current }
				unsafe { values[index] = temporary }
				next_position++
			} else if !has_next || current < next_bingo {
				next_bingo = current
				has_next = true
			}
			index++
		}
		if next_position == length { break }
		bingo = next_bingo
	}
}
