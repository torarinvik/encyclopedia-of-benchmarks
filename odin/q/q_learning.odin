package q_learning

import "core:c"
import "core:math"

MAX_PARSEABLE_INPUT_LENGTH :: 11

exact_integer :: proc(value: f64, minimum, maximum: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(minimum) || value > f64(maximum) do return false
	return f64(i64(value)) == value
}

@(export)
q_learning_update :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 6 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 0, 1) || !exact_integer(input[5], 0, 4) do return -1
	done := input[0] == 1.0
	alpha, gamma, reward, old_q := input[1], input[2], input[3], input[4]
	next_action_count := int(input[5])
	if input_length != c.size_t(6 + next_action_count) do return -1
	if math.is_nan(alpha) || math.is_inf(alpha) || alpha < 0 || alpha > 1 do return -1
	if math.is_nan(gamma) || math.is_inf(gamma) || gamma < 0 || gamma > 1 do return -1
	if math.is_nan(reward) || math.is_inf(reward) || reward < -100 || reward > 100 do return -1
	if math.is_nan(old_q) || math.is_inf(old_q) || old_q < -100 || old_q > 100 do return -1
	for index := 0; index < next_action_count; index += 1 {
		value := input[6 + index]
		if math.is_nan(value) || math.is_inf(value) || value < -100 || value > 100 do return -1
	}

	max_q_next := 0.0
	if !done && next_action_count > 0 {
		max_q_next = input[6]
		for index := 1; index < next_action_count; index += 1 {
			if input[6 + index] > max_q_next do max_q_next = input[6 + index]
		}
	}
	updated := (1.0 - alpha) * old_q + alpha * (reward + gamma * max_q_next)
	if math.is_nan(updated) || math.is_inf(updated) do return -1
	if output == nil || capacity < 1 do return -2
	output[0] = updated
	return 1
}
