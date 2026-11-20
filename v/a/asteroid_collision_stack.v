module asteroid_collision_stack

const max_n = 64
const max_input = 66

@[export: 'asteroid_collision_stack']
pub fn asteroid_collision_stack(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_input {
		return -1
	}
	n_word := input[0]
	if n_word < 0 || n_word > max_n || length != usize(n_word + 1) {
		return -1
	}

	mut stack := [max_n]i64{}
	mut top := 0
	for i in 0 .. int(n_word) {
		word := input[i + 1]
		if word == 0 || word < -127 || word > 127 {
			return -1
		}
		incoming := word
		mut alive := true
		for alive && top > 0 && stack[top - 1] > 0 && incoming < 0 {
			left_size := int(stack[top - 1])
			right_size := -int(incoming)
			if left_size < right_size {
				top--
			} else if left_size == right_size {
				top--
				alive = false
			} else {
				alive = false
			}
		}
		if alive {
			stack[top] = incoming
			top++
		}
	}

	required := top + 1
	if output == nil || capacity < usize(required) {
		return -2
	}
	output[0] = u8(top)
	for i in 0 .. top {
		output[i + 1] = u8(stack[i] & 255)
	}
	return i64(required)
}
