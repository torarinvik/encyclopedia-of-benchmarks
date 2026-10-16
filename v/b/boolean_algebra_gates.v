module boolean_algebra_gates

const max_input_count = 4096
const invalid_result = i64(-1)

@[export: 'boolean_algebra_gates']
pub fn boolean_algebra_gates(values &i64, length usize) i64 {
	if length < 2 || length > max_input_count + 2 { return invalid_result }
	gate := unsafe { values[0] }
	count := unsafe { values[1] }
	if gate < 0 || gate > 5 || count < 0 || count > max_input_count { return invalid_result }
	if usize(count) != length - 2 { return invalid_result }
	if gate == 2 && count != 1 { return invalid_result }
	mut result := i64(0)
	if gate == 0 || gate == 4 { result = 1 }
	for index in 0 .. int(count) {
		bit := unsafe { values[index + 2] }
		if bit != 0 && bit != 1 { return invalid_result }
		if gate == 0 || gate == 4 { result &= bit }
		else if gate == 1 || gate == 5 { result |= bit }
		else if gate == 2 { result = 1 - bit }
		else { result = result ^ bit }
	}
	if gate == 4 || gate == 5 { result = 1 - result }
	return result
}
