module recursive_linear_search

fn search_from_end(items &i64, count usize, target i64) i64 {
	if count == 0 { return -1 }
	if unsafe { items[count - 1] } == target { return i64(count - 1) }
	return search_from_end(items, count - 1, target)
}

@[export: 'recursive_linear_search']
pub fn recursive_linear_search(values &i64, length usize) i64 {
	if length < 2 || length > 67 { return -1 }
	unsafe {
		count_value := values[0]
		target := values[1]
		if count_value < 1 || count_value > 64 { return -1 }
		count := usize(count_value)
		if length != count + 2 { return -1 }
		items := values + 2
		return search_from_end(items, count, target)
	}
}
