module domino_l_tromino_tilings_2xn

const max_width = i64(32)
const max_parseable_length = usize(2)

fn count_tilings(width i64) i64 {
	mut state0 := i64(1)
	mut state1 := i64(0)
	mut state2 := i64(0)
	mut state3 := i64(0)
	for column := 0; column < int(width); column++ {
		next0 := state0 + state3
		next1 := state0 + state2
		next2 := state0 + state1
		next3 := state0 + state1 + state2
		state0 = next0
		state1 = next1
		state2 = next2
		state3 = next3
	}
	return state0
}

@[export: 'domino_l_tromino_tilings_2xn']
pub fn domino_l_tromino_tilings_2xn(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		if length != 1 || input[0] < 0 || input[0] > max_width { return -1 }
		return count_tilings(input[0])
	}
}
