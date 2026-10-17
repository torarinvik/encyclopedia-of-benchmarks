module momentum_sgd

const max_group_count = 8
const max_vector_length = 16
const max_group_vector_elements = 32
const max_call_count = 8
const max_parseable_input_length = 270

@[export: 'momentum_sgd']
pub fn momentum_sgd(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > usize(max_parseable_input_length) { return -1 }
		group_value, vector_value, calls_value := input[0], input[1], input[2]
		if group_value != group_value || group_value < 1.0 || group_value > f64(max_group_count) { return -1 }
		if vector_value != vector_value || vector_value < 1.0 || vector_value > f64(max_vector_length) { return -1 }
		if calls_value != calls_value || calls_value < 1.0 || calls_value > f64(max_call_count) { return -1 }
		group_count, vector_length, call_count := int(group_value), int(vector_value), int(calls_value)
		if group_value != f64(group_count) || vector_value != f64(vector_length) || calls_value != f64(call_count) { return -1 }
		if group_count*vector_length > max_group_vector_elements || call_count < group_count { return -1 }
		if input_length != usize(5 + call_count*(1+2*vector_length)) { return -1 }

		learning_rate, momentum := input[3], input[4]
		if learning_rate != learning_rate || learning_rate < 1e-6 || learning_rate > 1.0 { return -1 }
		if momentum != momentum || momentum < 0.0 || momentum > 0.99 { return -1 }

		mut ids := [max_call_count]int{}
		mut event_params := [max_call_count * max_vector_length]f64{}
		mut event_gradients := [max_call_count * max_vector_length]f64{}
		mut seen := [max_group_count]bool{}
		mut cursor := 5
		for event in 0 .. call_count {
			id_value := input[cursor]
			if id_value != id_value || id_value < 0.0 || id_value >= f64(group_count) { return -1 }
			id := int(id_value)
			if id_value != f64(id) { return -1 }
			ids[event] = id
			seen[id] = true
			cursor++
			for component in 0 .. vector_length {
				value := input[cursor+component]
				if value != value || value < -1000.0 || value > 1000.0 { return -1 }
				event_params[event*vector_length+component] = value
			}
			cursor += vector_length
			for component in 0 .. vector_length {
				value := input[cursor+component]
				if value != value || value < -1000.0 || value > 1000.0 { return -1 }
				event_gradients[event*vector_length+component] = value
			}
			cursor += vector_length
		}
		for id in 0 .. group_count {
			if !seen[id] { return -1 }
		}
		group_elements := group_count * vector_length
		if output == nil || output_capacity < usize(2*group_elements) { return -2 }

		mut velocities := [max_group_vector_elements]f64{}
		mut last_params := [max_group_vector_elements]f64{}
		for event in 0 .. call_count {
			id := ids[event]
			for component in 0 .. vector_length {
				state_index := id*vector_length+component
				event_index := event*vector_length+component
				updated_velocity := momentum*velocities[state_index] - learning_rate*event_gradients[event_index]
				velocities[state_index] = updated_velocity
				last_params[state_index] = event_params[event_index] + updated_velocity
			}
		}
		for index in 0 .. group_elements {
			output[index] = last_params[index]
			output[group_elements+index] = velocities[index]
		}
		return i64(2*group_elements)
	}
}
