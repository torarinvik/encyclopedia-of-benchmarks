module longest_square_streak

const max_input_length = 100_000
const max_value = 100_000
const required_workspace = 4 * (max_value + 1)

fn read_state(workspace &u8, value int) i64 {
	position := 4 * value
	return unsafe {
		i64(workspace[position]) | (i64(workspace[position + 1]) << 8) |
			(i64(workspace[position + 2]) << 16) | (i64(workspace[position + 3]) << 24)
	}
}

fn write_state(mut workspace &u8, value int, state i64) {
	mut encoded := state
	if encoded < 0 { encoded += 4_294_967_296 }
	position := 4 * value
	unsafe {
		workspace[position] = u8(encoded & 255)
		workspace[position + 1] = u8((encoded >> 8) & 255)
		workspace[position + 2] = u8((encoded >> 16) & 255)
		workspace[position + 3] = u8((encoded >> 24) & 255)
	}
}

fn streak_from(mut workspace &u8, value int) i64 {
	state := read_state(workspace, value)
	if state > 1 { return state - 1 }
	mut chain_length := i64(1)
	square := i64(value) * i64(value)
	if square <= max_value && read_state(workspace, int(square)) != 0 {
		chain_length += streak_from(mut workspace, int(square))
	}
	write_state(mut workspace, value, chain_length + 1)
	return chain_length
}

@[export: 'longest_square_streak']
pub fn longest_square_streak(values &i64, length usize, mut workspace &u8,
		workspace_capacity usize) i64 {
	if length < 3 || length > max_input_length + 1 { return -1 }
	unsafe {
		if values[0] < 2 || values[0] > max_input_length || length != usize(values[0] + 1) {
			return -1
		}
		count := int(values[0])
		for index in 0 .. count {
			if values[index + 1] < 2 || values[index + 1] > max_value { return -1 }
		}
		if workspace_capacity < required_workspace { return -2 }
		for workspace_index in 0 .. required_workspace {
			workspace[workspace_index] = u8(0)
		}
		for index in 0 .. count {
			write_state(mut workspace, int(values[index + 1]), 1)
		}
		mut longest := i64(1)
		for index in 0 .. count {
			found := streak_from(mut workspace, int(values[index + 1]))
			if found > longest { longest = found }
		}
		if longest >= 2 { return longest }
		return -1
	}
}
