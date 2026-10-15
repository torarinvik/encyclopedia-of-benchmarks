module average_margin_ranking_loss

const max_length = 256
const invalid_result = -1.0e300

@[export: 'average_margin_ranking_loss']
pub fn average_margin_ranking_loss(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 5 || length > 2 * max_length + 3 { return invalid_result }
	unsafe {
		count_value := values[0]
		margin_value := values[1]
		label_value := values[2]
		if count_value < 1 || count_value > max_length || length != usize(2 * count_value + 3) || margin_value < 0 || margin_value > 1000 || (label_value != 1 && label_value != -1) { return invalid_result }
		count := int(count_value)
		mut total := 0.0
		for index in 0 .. count {
			first := values[index + 3]
			second := values[index + 3 + count]
			if first < -1000 || first > 1000 || second < -1000 || second > 1000 { return invalid_result }
			loss := f64(margin_value) - f64(label_value) * (f64(first) - f64(second))
			if loss > 0 { total += loss }
		}
		return total / f64(count)
	}
}
