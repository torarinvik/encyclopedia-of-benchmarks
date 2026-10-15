module lower_bound

fn lower_bound_range(values &i64, target i64, left i64, right i64) i64 {
	if right <= left {
		return left
	}
	middle := (left + right) / 2
	value := unsafe { values[middle] }
	if target == value {
		return middle
	}
	if target < value {
		return lower_bound_range(values, target, left, middle)
	}
	return lower_bound_range(values, target, middle + 1, right)
}

@[export: 'lower_bound']
pub fn lower_bound(values &i64, length usize, target i64) i64 {
	if length > 512 || target < -2147483648 || target > 2147483647 {
		return -1
	}
	if length > 0 && isnil(values) {
		return -1
	}
	for i in 0 .. length {
		value := unsafe { values[i] }
		if value < -2147483648 || value > 2147483647 {
			return -1
		}
		if i > 0 && unsafe { values[i - 1] } > value {
			return -1
		}
	}
	return lower_bound_range(values, target, 0, i64(length) - 1)
}
