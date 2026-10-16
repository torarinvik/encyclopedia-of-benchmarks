module optimal_file_merging

@[export: 'optimal_file_merging']
pub fn optimal_file_merging(values &i64, length usize) i64 {
	if length < 1 || length > 33 { return -1 }
	count := unsafe { values[0] }
	if count < 0 || count > 32 || length != usize(count) + 1 { return -1 }
	mut files := []i64{len: 32}
	for i in 0 .. int(count) {
		item := unsafe { values[i + 1] }
		if item < 0 || item > 1_000_000 { return -1 }
		files[i] = item
	}
	mut n := int(count)
	mut total := i64(0)
	for n > 1 {
		mut a := 0
		mut b := 1
		if files[b] < files[a] { a, b = b, a }
		for i in 2 .. n {
			if files[i] < files[a] { b = a; a = i } else if files[i] < files[b] { b = i }
		}
		merged := files[a] + files[b]
		total += merged
		if a > b { a, b = b, a }
		files[a] = merged
		files[b] = files[n - 1]
		n--
	}
	return total
}
