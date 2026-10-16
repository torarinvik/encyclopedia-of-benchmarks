module double_linear_search_recursion

const max_items = 1024
const invalid_result = i64(-2)

fn search_range(values &i64, key i64, left i64, right i64, offset int) i64 {
	unsafe {
		if left > right { return -1 }
		if values[offset + int(left)] == key { return left }
		if values[offset + int(right)] == key { return right }
		return search_range(values, key, left + 1, right - 1, offset)
	}
}

@[export: 'double_linear_search_recursion']
pub fn double_linear_search_recursion(values &i64, length usize) i64 {
	unsafe {
		if isnil(values) || length < 2 || length > max_items + 2 { return invalid_result }
		count := values[0]
		key := values[1]
		if count < 0 || count > max_items || key < -2147483648 || key > 2147483647 ||
			length != usize(2 + count) { return invalid_result }
		for index in 0 .. int(count) {
			value := values[2 + index]
			if value < -2147483648 || value > 2147483647 { return invalid_result }
		}
		return search_range(values, key, 0, count - 1, 2)
	}
}
