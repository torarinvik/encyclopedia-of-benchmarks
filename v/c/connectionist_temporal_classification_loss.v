module connectionist_temporal_classification_loss

import math

const max_time = 32
const max_classes = 16
const max_target = 16
const max_input_length = 3 + max_target + max_time * max_classes
const max_states = 33
const neg_inf = -1.0e300
const invalid_result = -1.0e300

fn logaddexp_value(left f64, right f64) f64 {
	if left <= neg_inf / 2.0 { return right }
	if right <= neg_inf / 2.0 { return left }
	larger := if left > right { left } else { right }
	smaller := if left > right { right } else { left }
	return larger + math.log(1.0 + math.exp(smaller - larger))
}

@[export: 'connectionist_temporal_classification_loss']
pub fn connectionist_temporal_classification_loss(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 3 || length > max_input_length { return invalid_result }
	unsafe {
		time_value, classes_value, target_value := values[0], values[1], values[2]
		if time_value < 1 || time_value > max_time || classes_value < 2 || classes_value > max_classes || target_value < 1 || target_value > max_target { return invalid_result }
		time, classes, target_length := int(time_value), int(classes_value), int(target_value)
		probability_base := 3 + target_length
		if length != probability_base + time * classes { return invalid_result }
		mut repeated := 0
		for i in 0 .. target_length {
			target := values[3 + i]
			if target < 1 || target >= i64(classes) { return invalid_result }
			if i > 0 && target == values[3 + i - 1] { repeated++ }
		}
		if time < target_length + repeated { return invalid_result }
		for t in 0 .. time {
			mut row_sum := i64(0)
			for c in 0 .. classes {
				p := values[probability_base + t * classes + c]
				if p < 1 || p > 1_000_000 { return invalid_result }
				row_sum += p
			}
			if row_sum != 1_000_000 { return invalid_result }
		}
		states := 2 * target_length + 1
		mut extended := [max_states]i64{}
		mut previous := [max_states]f64{}
		mut current := [max_states]f64{}
		for s in 0 .. states {
			extended[s] = if s % 2 == 0 { 0 } else { values[3 + s / 2] }
			previous[s] = neg_inf
		}
		previous[0] = math.log(f64(values[probability_base]) / 1_000_000.0)
		previous[1] = math.log(f64(values[probability_base + int(extended[1])]) / 1_000_000.0)
		for t in 1 .. time {
			for s in 0 .. states {
				mut incoming := previous[s]
				if s > 0 { incoming = logaddexp_value(incoming, previous[s - 1]) }
				if s > 1 && extended[s] != extended[s - 2] { incoming = logaddexp_value(incoming, previous[s - 2]) }
				p := f64(values[probability_base + t * classes + int(extended[s])]) / 1_000_000.0
				current[s] = incoming + math.log(p)
			}
			for s in 0 .. states { previous[s] = current[s] }
		}
		return -logaddexp_value(previous[states - 1], previous[states - 2])
	}
}
