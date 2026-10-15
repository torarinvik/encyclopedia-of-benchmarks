module divisors_count_sequence

const max_index = i64(9999)

@[export: 'divisors_count_sequence']
pub fn divisors_count_sequence(index i64) i64 {
	if index < 0 || index > max_index { return -1 }
	n := index + 1
	if n == 1 { return 1 }
	mut count := i64(2)
	mut k := i64(2)
	for k < n {
		if n % k == 0 { count += 1 }
		k += 1
	}
	return count
}
