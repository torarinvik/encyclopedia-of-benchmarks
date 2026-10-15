module acronym

const max_phrase_length = 79

@[export: 'acronym']
pub fn acronym(phrase &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length > max_phrase_length { return -1 }
	mut required := usize(0)
	for index in 0 .. length {
		value := unsafe { phrase[index] }
		if value < 1 || value > 127 { return -1 }
		if value != 32 && (index == 0 || unsafe { phrase[index - 1] == 32 }) { required++ }
	}
	if output_capacity < required { return -2 }
	mut written := usize(0)
	for index in 0 .. length {
		value := unsafe { phrase[index] }
		if value != 32 && (index == 0 || unsafe { phrase[index - 1] == 32 }) {
			if value >= 97 && value <= 122 { value -= 32 }
			unsafe { output[written] = u8(value) }
			written++
		}
	}
	return i64(written)
}
