module n_bonacci

@[export: 'n_bonacci']
pub fn n_bonacci(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	order_value := unsafe { values[0] }
	count_value := unsafe { values[1] }
	if order_value < 1 || count_value <= order_value || count_value > 64 { return -1 }
	order := int(order_value)
	count := int(count_value)
	mut terms := [64]i64{}
	terms[order - 1] = 1
	terms[order] = 1
	for index in order + 1 .. count {
		terms[index] = 2 * terms[index - 1] - terms[index - 1 - order]
	}
	return terms[count - 1]
}
