module duval

// Least cyclic shift index using Duval's linear-time scan.
@[export: 'duval']
pub fn duval(values &i64, length usize) i64 {
	if length > 4096 { return -1 }
	if length == 0 { return 0 }
	mut index := usize(0)
	for index < length {
		value := unsafe { values[index] }
		if value < 0 || value > 127 { return -1 }
		index++
	}

	mut i := usize(0)
	mut answer := usize(0)
	for i < length {
		answer = i
		mut j := i + 1
		mut k := i
		for j < 2 * length && unsafe { values[j % length] >= values[k % length] } {
			if unsafe { values[k % length] < values[j % length] } {
				k = i
			} else {
				k++
			}
			j++
		}
		for i <= k { i += j - k }
	}
	return i64(answer)
}
