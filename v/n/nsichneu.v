module nsichneu

const input_count = 9
const output_count = 17
const output_bytes = output_count * 8
const max_runs = i64(64)

fn read_value(input &i64, index int) i64 {
	unsafe { return input[index] }
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
		}
	}
}

@[export: 'nsichneu']
pub fn nsichneu(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != input_count {
		return -1
	}
	runs := read_value(input, 0)
	if runs < 1 || runs > max_runs {
		return -1
	}
	for index in 1 .. input_count {
		value := read_value(input, index)
		if value < -1000 || value > 1000 {
			return -1
		}
	}
	if unsafe { output == nil } || capacity < usize(output_bytes) {
		return -2
	}

	mut p1 := [3]i64{}
	mut p2 := [5]i64{}
	mut p3 := [6]i64{}
	unsafe {
		for index in 0 .. 3 { p1[index] = input[index + 1] }
		for index in 0 .. 5 { p2[index] = input[index + 4] }
	}
	mut p1_count := i64(3)
	mut p2_count := i64(5)
	mut p3_count := i64(0)

	for _ in 0 .. int(runs) {
		p1_count = 3
		p2_count = 5
		p3_count = 0
		for first in 0 .. 3 {
			for second in 0 .. 3 {
				if second == first { continue }
				for third in 0 .. 3 {
					if third == first || third == second { continue }
					if p1_count >= 3 && p3_count + 3 <= 6 && p1[second] == p1[third] {
						x, y := p1[first], p1[second]
						if x < y {
							p1_count -= 3
							p3[int(p3_count)] = x
							p3[int(p3_count + 1)] = y
							p3[int(p3_count + 2)] = x - y
							p3_count += 3
						}
					}
				}
			}
		}

		for subset_number in 0 .. 5 {
			omitted := 4 - subset_number
			mut subset := [4]int{}
			mut count := 0
			for index in 0 .. 5 {
				if index != omitted { subset[count] = index; count++ }
			}
			for a in 0 .. 4 {
				for b in 0 .. 4 {
					if b == a { continue }
					for c in 0 .. 4 {
						if c == a || c == b { continue }
						for d in 0 .. 4 {
							if d == a || d == b || d == c { continue }
							i0, i1, i2, i3 := subset[a], subset[b], subset[c], subset[d]
							if p2_count >= 4 && p3_count + 3 <= 6 && p2[i1] == p2[i2] && p2[i1] == p2[i3] {
								x, y := p2[i0], p2[i1]
								if y > x {
									p2_count -= 4
									p3[int(p3_count)] = x
									p3[int(p3_count + 1)] = y
									p3[int(p3_count + 2)] = x + y
									p3_count += 3
								}
							}
						}
					}
				}
			}
		}
	}

	mut snapshot := [output_count]i64{}
	mut position := 0
	snapshot[position] = p1_count
	position++
	for index in 0 .. 3 { snapshot[position] = p1[index]; position++ }
	snapshot[position] = p2_count
	position++
	for index in 0 .. 5 { snapshot[position] = p2[index]; position++ }
	snapshot[position] = p3_count
	position++
	for index in 0 .. 6 { snapshot[position] = p3[index]; position++ }
	for index in 0 .. output_count { put_i64_le(mut output, index * 8, snapshot[index]) }
	return i64(output_bytes)
}
