module sturmian_standard_word

const max_steps = 4
const max_word = 41

@[export: 'sturmian_standard_word']
pub fn sturmian_standard_word(values &i64, length usize, mut output &u8,
	capacity usize) i64 {
	if length < 1 || length > 6 || unsafe { values == nil } { return -1 }
	unsafe {
		steps_word := values[0]
		if steps_word < 0 || steps_word > max_steps { return -1 }
		steps := int(steps_word)
		if length != usize(steps + 1) { return -1 }
		mut directives := [max_steps]i64{}
		for i in 0 .. steps {
			repeat := values[i + 1]
			if i == 0 {
				if repeat < 0 || repeat > 2 { return -1 }
			} else {
				if repeat < 1 || repeat > 2 { return -1 }
			}
			directives[i] = repeat
		}

		mut previous := [max_word]u8{}
		mut current := [max_word]u8{}
		mut following := [max_word]u8{}
		previous[0] = u8(`b`)
		current[0] = u8(`a`)
		mut previous_length := 1
		mut current_length := 1
		for step in 0 .. steps {
			repeat := int(directives[step])
			following_length := current_length * repeat + previous_length
			mut position := 0
			for _ in 0 .. repeat {
				for i in 0 .. current_length {
					following[position] = current[i]
					position++
				}
			}
			for i in 0 .. previous_length {
				following[position] = previous[i]
				position++
			}
			for i in 0 .. current_length { previous[i] = current[i] }
			for i in 0 .. following_length { current[i] = following[i] }
			previous_length = current_length
			current_length = following_length
		}

		if output == nil || capacity < usize(current_length) { return -2 }
		for i in 0 .. current_length { output[i] = current[i] }
		return i64(current_length)
	}
}
