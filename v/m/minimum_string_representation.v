module minimum_string_representation

// Least cyclic rotation by two-candidate elimination.
@[export: 'minimum_string_representation']
pub fn minimum_string_representation(values &i64, length usize) i64 {
	if length > 4096 { return -1 }
	if length == 0 { return 0 }
	mut index := usize(0)
	for index < length {
		value := unsafe { values[index] }
		if value < 0 || value > 127 { return -1 }
		index++
	}

	mut left := usize(0)
	mut right := usize(1)
	mut matched := usize(0)
	for left < length && right < length && matched < length {
		a := unsafe { values[(left + matched) % length] }
		b := unsafe { values[(right + matched) % length] }
		if a == b {
			matched++
			continue
		}
		if a > b {
			left += matched + 1
			if left == right { left++ }
		} else {
			right += matched + 1
			if left == right { right++ }
		}
		matched = 0
	}
	if left < right { return i64(left) }
	return i64(right)
}
