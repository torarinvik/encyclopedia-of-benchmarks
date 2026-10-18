fn exact_integer(value f64, minimum i64, maximum i64) bool {
	if !value.is_finite() || value < f64(minimum) || value > f64(maximum) { return false }
	return f64(i64(value)) == value
}

@[export: 'q_learning_update']
pub fn q_learning_update(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 6 || input_length > 11 { return -1 }
		if !exact_integer(input[0], 0, 1) || !exact_integer(input[5], 0, 4) { return -1 }
		done := input[0] == 1.0
		alpha, gamma, reward, old_q := input[1], input[2], input[3], input[4]
		next_action_count := int(input[5])
		if input_length != usize(6 + next_action_count) { return -1 }
		if !alpha.is_finite() || alpha < 0 || alpha > 1 { return -1 }
		if !gamma.is_finite() || gamma < 0 || gamma > 1 { return -1 }
		if !reward.is_finite() || reward < -100 || reward > 100 { return -1 }
		if !old_q.is_finite() || old_q < -100 || old_q > 100 { return -1 }
		for index in 0 .. next_action_count {
			value := input[6 + index]
			if !value.is_finite() || value < -100 || value > 100 { return -1 }
		}

		mut max_q_next := 0.0
		if !done && next_action_count > 0 {
			max_q_next = input[6]
			for index in 1 .. next_action_count {
				if input[6 + index] > max_q_next { max_q_next = input[6 + index] }
			}
		}
		updated := (1.0 - alpha) * old_q + alpha * (reward + gamma * max_q_next)
		if !updated.is_finite() { return -1 }
		if output == nil || capacity < 1 { return -2 }
		output[0] = updated
		return 1
	}
}
