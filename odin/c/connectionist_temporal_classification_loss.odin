package connectionist_temporal_classification_loss

import "core:c"
import "core:math"

MAX_TIME :: 32
MAX_CLASSES :: 16
MAX_TARGET :: 16
MAX_STATES :: 33
MAX_INPUT_LENGTH :: 3 + MAX_TARGET + MAX_TIME * MAX_CLASSES
NEG_INF :: f64 = -1.0e300
INVALID_RESULT :: f64 = -1.0e300

logaddexp_value :: proc(left, right: f64) -> f64 {
	if left <= NEG_INF / 2.0 do return right
	if right <= NEG_INF / 2.0 do return left
	larger := left
	smaller := right
	if right > left {
		larger = right
		smaller = left
	}
	return larger + math.log_f64(1.0 + math.exp_f64(smaller - larger))
}

@(export)
connectionist_temporal_classification_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	time_value, classes_value, target_value := values[0], values[1], values[2]
	if time_value < 1 || time_value > MAX_TIME || classes_value < 2 || classes_value > MAX_CLASSES || target_value < 1 || target_value > MAX_TARGET do return INVALID_RESULT
	time, classes, target_length := int(time_value), int(classes_value), int(target_value)
	probability_base := 3 + target_length
	if length != c.size_t(probability_base + time * classes) do return INVALID_RESULT
	repeated := 0
	for i := 0; i < target_length; i += 1 {
		target := values[3 + i]
		if target < 1 || target >= i64(classes) do return INVALID_RESULT
		if i > 0 && target == values[3 + i - 1] do repeated += 1
	}
	if time < target_length + repeated do return INVALID_RESULT
	for t := 0; t < time; t += 1 {
		row_sum := i64(0)
		for col := 0; col < classes; col += 1 {
			p := values[probability_base + t * classes + col]
			if p < 1 || p > 1_000_000 do return INVALID_RESULT
			row_sum += p
		}
		if row_sum != 1_000_000 do return INVALID_RESULT
	}
	states := 2 * target_length + 1
	extended: [MAX_STATES]i64
	previous: [MAX_STATES]f64
	current: [MAX_STATES]f64
	for s := 0; s < states; s += 1 {
		extended[s] = 0
		if s % 2 != 0 do extended[s] = values[3 + s / 2]
		previous[s] = NEG_INF
	}
	previous[0] = math.log_f64(f64(values[probability_base]) / 1_000_000.0)
	previous[1] = math.log_f64(f64(values[probability_base + int(extended[1])]) / 1_000_000.0)
	for t := 1; t < time; t += 1 {
		for s := 0; s < states; s += 1 {
			incoming := previous[s]
			if s > 0 do incoming = logaddexp_value(incoming, previous[s - 1])
			if s > 1 && extended[s] != extended[s - 2] do incoming = logaddexp_value(incoming, previous[s - 2])
			p := f64(values[probability_base + t * classes + int(extended[s])]) / 1_000_000.0
			current[s] = incoming + math.log_f64(p)
		}
		for s := 0; s < states; s += 1 do previous[s] = current[s]
	}
	return -logaddexp_value(previous[states - 1], previous[states - 2])
}
