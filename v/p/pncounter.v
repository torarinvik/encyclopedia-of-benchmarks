module pncounter

const max_nodes = 16
const max_operations = 64
const max_input_length = 5 + max_operations
const max_output_words = 2 * max_operations
const pair_left = [6]int{0, 0, 1, 1, 2, 2}
const pair_right = [6]int{1, 2, 0, 2, 0, 1}

struct CounterTrace {
	mut:
	positive [3][max_nodes]i64
	negative [3][max_nodes]i64
}

fn append_word(mut words [max_output_words]i64, mut count int, value i64) {
	words[count] = value
	count++
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & u64(255)) }
	}
}

@[export: 'pncounter']
pub fn pncounter(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > usize(max_input_length) { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_nodes || input[4] < 0 || input[4] > max_operations { return -1 }
		mut ids := [3]int{int(input[1]), int(input[2]), int(input[3])}
		for counter in 0 .. 3 {
			if ids[counter] < 0 || ids[counter] >= int(input[0]) { return -1 }
		}
		operation_count := int(input[4])
		if length != usize(5 + operation_count) { return -1 }

		mut state := CounterTrace{}
		mut words := [max_output_words]i64{}
		mut word_count := 0
		mut position := 5
		for _ in 0 .. operation_count {
			opcode := input[position]
			position++
			if opcode < 0 || opcode > 20 { return -1 }
			if opcode < 6 {
				counter := int(opcode / 2)
				if opcode % 2 == 0 { state.positive[counter][ids[counter]]++ }
				else { state.negative[counter][ids[counter]]++ }
				append_word(mut words, mut word_count, opcode)
			} else if opcode < 9 {
				counter := int(opcode - 6)
				mut value := i64(0)
				for node in 0 .. int(input[0]) {
					value += state.positive[counter][node] - state.negative[counter][node]
				}
				append_word(mut words, mut word_count, opcode)
				append_word(mut words, mut word_count, value)
			} else if opcode < 15 {
				pair := int(opcode - 9)
				target, source := pair_left[pair], pair_right[pair]
				for node in 0 .. int(input[0]) {
					state.positive[target][node] = max(state.positive[target][node], state.positive[source][node])
					state.negative[target][node] = max(state.negative[target][node], state.negative[source][node])
				}
				append_word(mut words, mut word_count, opcode)
			} else {
				pair := int(opcode - 15)
				left, right := pair_left[pair], pair_right[pair]
				mut result := i64(1)
				for node in 0 .. int(input[0]) {
					if state.positive[left][node] > state.positive[right][node] &&
						state.negative[left][node] > state.negative[right][node] {
						result = 0
						break
					}
				}
				append_word(mut words, mut word_count, opcode)
				append_word(mut words, mut word_count, result)
			}
		}
		bytes := word_count * 8
		if output == nil || output_capacity < usize(bytes) { return -2 }
		for i in 0 .. word_count { put_i64_le(mut output, i * 8, words[i]) }
		return i64(bytes)
	}
}
