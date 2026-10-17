package momentum_sgd

import "core:c"

MAX_GROUP_COUNT :: 8
MAX_VECTOR_LENGTH :: 16
MAX_GROUP_VECTOR_ELEMENTS :: 32
MAX_CALL_COUNT :: 8
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(270)

momentum_sgd :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	group_value, vector_value, calls_value := input[0], input[1], input[2]
	if group_value != group_value || group_value < 1.0 || group_value > f64(MAX_GROUP_COUNT) do return -1
	if vector_value != vector_value || vector_value < 1.0 || vector_value > f64(MAX_VECTOR_LENGTH) do return -1
	if calls_value != calls_value || calls_value < 1.0 || calls_value > f64(MAX_CALL_COUNT) do return -1
	group_count, vector_length, call_count := int(group_value), int(vector_value), int(calls_value)
	if group_value != f64(group_count) || vector_value != f64(vector_length) || calls_value != f64(call_count) do return -1
	if group_count*vector_length > MAX_GROUP_VECTOR_ELEMENTS || call_count < group_count do return -1
	if input_length != c.size_t(5+call_count*(1+2*vector_length)) do return -1

	learning_rate, momentum := input[3], input[4]
	if learning_rate != learning_rate || learning_rate < 1e-6 || learning_rate > 1.0 do return -1
	if momentum != momentum || momentum < 0.0 || momentum > 0.99 do return -1

	ids: [MAX_CALL_COUNT]int
	event_params: [MAX_CALL_COUNT*MAX_VECTOR_LENGTH]f64
	event_gradients: [MAX_CALL_COUNT*MAX_VECTOR_LENGTH]f64
	seen: [MAX_GROUP_COUNT]bool
	cursor := 5
	for event := 0; event < call_count; event += 1 {
		id_value := input[cursor]
		if id_value != id_value || id_value < 0.0 || id_value >= f64(group_count) do return -1
		id := int(id_value)
		if id_value != f64(id) do return -1
		ids[event] = id
		seen[id] = true
		cursor += 1
		for component := 0; component < vector_length; component += 1 {
			value := input[cursor+component]
			if value != value || value < -1000.0 || value > 1000.0 do return -1
			event_params[event*vector_length+component] = value
		}
		cursor += vector_length
		for component := 0; component < vector_length; component += 1 {
			value := input[cursor+component]
			if value != value || value < -1000.0 || value > 1000.0 do return -1
			event_gradients[event*vector_length+component] = value
		}
		cursor += vector_length
	}
	for id := 0; id < group_count; id += 1 {
		if !seen[id] do return -1
	}
	output_elements := 2*group_count*vector_length
	if output == nil || output_capacity < c.size_t(output_elements) do return -2

	velocities: [MAX_GROUP_VECTOR_ELEMENTS]f64
	last_params: [MAX_GROUP_VECTOR_ELEMENTS]f64
	for event := 0; event < call_count; event += 1 {
		id := ids[event]
		for component := 0; component < vector_length; component += 1 {
			state_index := id*vector_length+component
			event_index := event*vector_length+component
			updated_velocity := momentum*velocities[state_index] - learning_rate*event_gradients[event_index]
			velocities[state_index] = updated_velocity
			last_params[state_index] = event_params[event_index] + updated_velocity
		}
	}
	for index := 0; index < group_count*vector_length; index += 1 {
		output[index] = last_params[index]
		output[group_count*vector_length+index] = velocities[index]
	}
	return i64(output_elements)
}
