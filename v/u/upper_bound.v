module upper_bound

fn upper_bound_range(values &i64, target i64, left i64, right i64) i64 {
	if right <= left {
		return left
	}
	middle := (left + right) / 2
	value := unsafe { values[middle + 1] }
	if target < value {
		return upper_bound_range(values, target, left, middle)
	}
	return upper_bound_range(values, target, middle + 1, right)
}

@[export: 'upper_bound']
pub fn upper_bound(values &i64, length usize) i64 {
	if values == nil || length == 0 || length > 513 {
		return -1
	}
	target := unsafe { values[0] }
	if target < -2147483648 || target > 2147483647 {
		return -1
	}
	array_length := length - 1
	for i in 0 .. array_length {
		value := unsafe { values[i + 1] }
		if value < -2147483648 || value > 2147483647 {
			return -1
		}
		if i > 0 && unsafe { values[i] } > value {
			return -1
		}
	}
	return upper_bound_range(values, target, 0, i64(array_length) - 1)
}
