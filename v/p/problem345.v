module problem345

const max_dimension = 15
const max_states = 1 << max_dimension

fn bit_count(mut value u32) int {
	mut count := 0
	for value != 0 {
		count += int(value & 1)
		value >>= 1
	}
	return count
}

@[export: 'problem345']
pub fn problem345(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_dimension * max_dimension + 1 { return -1 }
	dimension := unsafe { input[0] }
	if dimension < 1 || dimension > max_dimension || int(length) != int(dimension * dimension) + 1 { return -1 }
	for index in 1 .. int(length) {
		value := unsafe { input[index] }
		if value < 0 || value > 1000 { return -1 }
	}
	mut best := [max_states]i64{}
	for mask in 0 .. max_states { best[mask] = -1 }
	best[0] = 0
	state_count := 1 << int(dimension)
	for mask in 0 .. state_count {
		if best[mask] < 0 { continue }
		row := bit_count(u32(mask))
		if row >= int(dimension) { continue }
		for column in 0 .. int(dimension) {
			bit := 1 << column
			if mask & bit != 0 { continue }
			next := mask | bit
			value_index := 1 + row * int(dimension) + column
			candidate := best[mask] + unsafe { input[value_index] }
			if candidate > best[next] { best[next] = candidate }
		}
	}
	return best[state_count - 1]
}
