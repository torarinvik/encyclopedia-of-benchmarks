module metropolis_hastings_asymmetric_proposal

const max_states = 8
const max_steps = 64
const max_input = 267
const max_output = 65

@[export: 'metropolis_hastings_asymmetric_proposal']
pub fn metropolis_hastings_asymmetric_proposal(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_input) { return -1 }
		n64 := input[0]
		steps64 := input[1]
		initial64 := input[2]
		if n64 < 2 || n64 > max_states || steps64 < 0 || steps64 > max_steps || initial64 < 0 || initial64 >= n64 { return -1 }
		n := int(n64)
		steps := int(steps64)
		weights_start := 3
		matrix_start := weights_start + n
		proposals_start := matrix_start + n*n
		draws_start := proposals_start + steps
		if length != usize(draws_start + 2*steps) { return -1 }
		for state in 0 .. n {
			if input[weights_start + state] < 1 || input[weights_start + state] > 1024 { return -1 }
		}
		for row in 0 .. n {
			mut row_sum := i64(0)
			for column in 0 .. n {
				q := input[matrix_start + row*n + column]
				if q < 0 || q > 1024 { return -1 }
				row_sum += q
			}
			if row_sum != 1024 { return -1 }
		}

		mut staged := [max_output]u8{}
		mut current := int(initial64)
		staged[0] = u8(current)
		for step in 0 .. steps {
			proposal64 := input[proposals_start + step]
			draw_num := input[draws_start + 2*step]
			draw_den := input[draws_start + 2*step + 1]
			if proposal64 < 0 || proposal64 >= n64 || draw_den < 1 || draw_den > 1024 || draw_num < 0 || draw_num >= draw_den { return -1 }
			proposal := int(proposal64)
			forward := input[matrix_start + current*n + proposal]
			if forward == 0 { return -1 }
			reverse := input[matrix_start + proposal*n + current]
			numerator := input[weights_start + proposal] * reverse
			denominator := input[weights_start + current] * forward
			if numerator >= denominator || draw_num*denominator < draw_den*numerator { current = proposal }
			staged[step + 1] = u8(current)
		}

		needed := steps + 1
		if output == nil || capacity < usize(needed) { return -2 }
		for index in 0 .. needed { output[index] = staged[index] }
		return i64(needed)
	}
}
