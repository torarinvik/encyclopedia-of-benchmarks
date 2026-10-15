module parity_outlier

@[export: 'parity_outlier']
pub fn parity_outlier(values &i64, length usize) i64 {
	if length < 1 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 3 || count_value > 65 || count_value % 2 == 0 { return -1 }
	count := int(count_value)
	if length != usize(count + 1) { return -1 }
	mut evens := 0
	mut odds := 0
	mut even_value := i64(0)
	mut odd_value := i64(0)
	for i in 0 .. count {
		value := unsafe { values[i + 1] }
		if value < 0 || value > 2147483647 { return -1 }
		if value % 2 == 0 {
			evens++
			even_value = value
		} else {
			odds++
			odd_value = value
		}
	}
	if evens == 1 && odds >= 2 { return even_value }
	if odds == 1 && evens >= 2 { return odd_value }
	return -1
}
