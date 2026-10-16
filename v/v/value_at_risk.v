module value_at_risk

const scale = i64(1_000_000)
const max_returns = 64
const max_parsed_returns = i64(65)
const max_sample = i64(1_000_000_000)
const max_input_length = usize(67)
const invalid_result = -1.0e300

fn sift_down(mut values &f64, root_start int, end_value int) {
	mut root := root_start
	for root < end_value / 2 {
		mut child := root * 2 + 1
		if child + 1 < end_value && unsafe { values[child] < values[child + 1] } { child++ }
		if unsafe { values[root] >= values[child] } { break }
		unsafe {
			temporary := values[root]
			values[root] = values[child]
			values[child] = temporary
		}
		root = child
	}
}

fn heap_sort(mut values &f64, length int) {
	mut start := length / 2
	for start > 0 {
		start--
		sift_down(mut values, start, length)
	}
	mut ending := length
	for ending > 1 {
		ending--
		unsafe {
			temporary := values[0]
			values[0] = values[ending]
			values[ending] = temporary
		}
		sift_down(mut values, 0, ending)
	}
}

@[export: 'value_at_risk']
pub fn value_at_risk(input &i64, length usize) f64 {
	if length < 2 || length > max_input_length || unsafe { input == nil } { return invalid_result }
	confidence_micro, count_value := unsafe { input[0] }, unsafe { input[1] }
	if confidence_micro < 1 || confidence_micro >= scale || count_value < 1 || count_value > max_parsed_returns { return invalid_result }
	if length != usize(2 + count_value) || count_value > i64(max_returns) { return invalid_result }
	count := int(count_value)
	mut returns := [max_returns]f64{init: 0.0}
	unsafe {
		for index in 0 .. count {
			value := input[2 + index]
			if value < -max_sample || value > max_sample { return invalid_result }
			returns[index] = f64(value) / f64(scale)
		}
	}
	heap_sort(mut returns[0], count)
	confidence := f64(confidence_micro) / f64(scale)
	quantile := 1.0 - confidence
	position := f64(count - 1) * quantile
	lower := int(position)
	fraction := position - f64(lower)
	mut threshold := returns[lower]
	if lower + 1 < count { threshold = returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction }
	return -threshold
}
