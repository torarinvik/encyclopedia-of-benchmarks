module assembly_line_scheduling

// Minimum time to cross two assembly lines using station-by-station dynamic programming.
@[export: 'assembly_line_scheduling']
pub fn assembly_line_scheduling(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length < 7 { return -1 }
	if unsafe { values[0] < 1 || values[0] > 64 } { return -1 }
	n := int(unsafe { values[0] })
	if length != usize(4 * n + 3) { return -1 }
	for index in 0 .. length {
		value := unsafe { values[index] }
		if value < 0 || value > 1000 { return -1 }
	}

	a0 := 1
	a1 := a0 + n
	t0 := a1 + n
	t1 := t0 + n - 1
	entry := t1 + n - 1
	mut line0 := unsafe { values[entry] + values[a0] }
	mut line1 := unsafe { values[entry + 1] + values[a1] }
	for station in 1 .. n {
		stay0 := line0 + unsafe { values[a0 + station] }
		switch0 := line1 + unsafe { values[t1 + station - 1] } + unsafe { values[a0 + station] }
		stay1 := line1 + unsafe { values[a1 + station] }
		switch1 := line0 + unsafe { values[t0 + station - 1] } + unsafe { values[a1 + station] }
		line0 = if stay0 < switch0 { stay0 } else { switch0 }
		line1 = if stay1 < switch1 { stay1 } else { switch1 }
	}
	total0 := line0 + unsafe { values[entry + 2] }
	total1 := line1 + unsafe { values[entry + 3] }
	answer := if total0 < total1 { total0 } else { total1 }
	if output_capacity < 4 { return -2 }
	for byte in 0 .. 4 {
		unsafe { output[byte] = u8((answer >> (8 * byte)) & 255) }
	}
	return 4
}
