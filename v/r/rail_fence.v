module rail_fence

fn rail_for_position(position int, rails int) int {
	period := 2 * (rails - 1)
	phase := position % period
	if phase < rails { return phase }
	return period - phase
}

@[export: 'rail_fence']
pub fn rail_fence(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 260 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 1 || input[1] < 2 || input[1] > 8 { return -1 }
		if input[2] < 0 || input[2] > 256 { return -1 }
		mode := int(input[0])
		rails := int(input[1])
		n := int(input[2])
		if length != usize(n + 3) { return -1 }
		for i in 0 .. n {
			if input[i + 3] < 0 || input[i + 3] > 127 { return -1 }
		}
		if output == nil || output_capacity < usize(n) { return -2 }
		if mode == 0 {
			mut out_index := 0
			for rail in 0 .. rails {
				for position in 0 .. n {
					if rail_for_position(position, rails) == rail {
						output[out_index] = u8(input[position + 3])
						out_index++
					}
				}
			}
		} else {
			mut counts := [8]int{}
			mut starts := [8]int{}
			mut used := [8]int{}
			for position in 0 .. n {
				counts[rail_for_position(position, rails)]++
			}
			for rail in 1 .. rails {
				starts[rail] = starts[rail - 1] + counts[rail - 1]
			}
			for position in 0 .. n {
				rail := rail_for_position(position, rails)
				output[position] = u8(input[3 + starts[rail] + used[rail]])
				used[rail]++
			}
		}
		return i64(n)
	}
}
