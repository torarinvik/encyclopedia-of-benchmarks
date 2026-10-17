module pipeline

const max_stage_count = 32
const max_input_length = 66

@[export: 'pipeline']
pub fn pipeline(values &i64, length usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	unsafe {
		if values == nil { return -1 }
		initial := values[0]
		stage_count := values[1]
		if initial < 0 || initial > 2 || stage_count < 1 || stage_count > max_stage_count { return -1 }
		if length != usize(2 + 2 * stage_count) { return -1 }

		mut result := initial
		for index in 0 .. int(stage_count) {
			operation := values[2 + 2 * index]
			argument := values[3 + 2 * index]
			if argument < 0 || argument > 2 { return -1 }
			if operation == 0 { result += argument }
			else if operation == 1 { result *= argument }
			else { return -1 }
		}
		return result
	}
}
