module nagel_schrekenberg

@[export: 'nagel_schrekenberg']
pub fn nagel_schrekenberg(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 5 { return -1 }
	cells0 := unsafe { values[0] }; steps0 := unsafe { values[1] }; vmax := unsafe { values[2] }
	if cells0 < 2 || cells0 > 32 || steps0 < 0 || steps0 > 16 || vmax < 0 || vmax > 5 || length != usize(cells0+3) { return -1 }
	cells := int(cells0); steps := int(steps0)
	mut row := [32]i64{}
	for i in 0 .. cells { x := unsafe { values[i+3] }; if x < -1 || x > 5 { return -1 }; row[i] = x }
	need := cells*(steps+1); if usize(need) > capacity || isnil(output) { return -2 }
	mut pos := 0
	for j in 0 .. cells { unsafe { output[pos] = u8(row[j]+1) }; pos++ }
	for _ in 0 .. steps {
		mut next := [32]i64{}
		for i in 0 .. cells { next[i] = -1; if row[i] != -1 {
			mut distance := 0; mut j := i+1
			for j < cells && row[j] == -1 { distance++; j++ }
			if j == cells { j = 0; for row[j] == -1 { distance++; j++ } }
			mut speed := row[i]+1; if speed > vmax { speed = vmax }; if speed > i64(distance)-1 { speed = i64(distance)-1 }; next[i] = speed
		} }
		mut moved := [32]i64{}; for i in 0 .. cells { moved[i] = -1 }
		for i in 0 .. cells { if next[i] != -1 { moved[(i+int(next[i]))%cells] = next[i] } }
		row = moved; for j in 0 .. cells { unsafe { output[pos] = u8(row[j]+1) }; pos++ }
	}
	return i64(pos)
}
