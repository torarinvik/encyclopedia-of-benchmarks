package nsichneu

import "core:c"

INPUT_COUNT :: 9
OUTPUT_COUNT :: 17
OUTPUT_BYTES :: OUTPUT_COUNT * 8
MAX_RUNS :: 64

@(export)
nsichneu :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != INPUT_COUNT || input[0] < 1 || input[0] > MAX_RUNS do return -1
	for index := 1; index < INPUT_COUNT; index += 1 {
		if input[index] < -1000 || input[index] > 1000 do return -1
	}
	if output == nil || capacity < OUTPUT_BYTES do return -2

	p1: [3]i64 = {input[1], input[2], input[3]}
	p2: [5]i64 = {input[4], input[5], input[6], input[7], input[8]}
	p3: [6]i64 = {}
	p1_count := i64(3)
	p2_count := i64(5)
	p3_count := i64(0)

	for run := i64(0); run < input[0]; run += 1 {
		p1_count = 3
		p2_count = 5
		p3_count = 0
		for first := 0; first < 3; first += 1 {
			for second := 0; second < 3; second += 1 {
				if second == first do continue
				for third := 0; third < 3; third += 1 {
					if third == first || third == second do continue
					if p1_count >= 3 && p3_count + 3 <= 6 && p1[second] == p1[third] {
						x, y := p1[first], p1[second]
						if x < y {
							p1_count -= 3
							p3[int(p3_count)] = x
							p3[int(p3_count+1)] = y
							p3[int(p3_count+2)] = x - y
							p3_count += 3
						}
					}
				}
			}
		}

		for subset_number := 0; subset_number < 5; subset_number += 1 {
			omitted := 4 - subset_number
			subset: [4]int
			count := 0
			for index := 0; index < 5; index += 1 {
				if index != omitted { subset[count] = index; count += 1 }
			}
			for a := 0; a < 4; a += 1 {
				for b := 0; b < 4; b += 1 {
					if b == a do continue
					for c := 0; c < 4; c += 1 {
						if c == a || c == b do continue
						for d := 0; d < 4; d += 1 {
							if d == a || d == b || d == c do continue
							i0, i1, i2, i3 := subset[a], subset[b], subset[c], subset[d]
							if p2_count >= 4 && p3_count + 3 <= 6 && p2[i1] == p2[i2] && p2[i1] == p2[i3] {
								x, y := p2[i0], p2[i1]
								if y > x {
									p2_count -= 4
									p3[int(p3_count)] = x
									p3[int(p3_count+1)] = y
									p3[int(p3_count+2)] = x + y
									p3_count += 3
								}
							}
						}
					}
				}
			}
		}
	}

	snapshot: [OUTPUT_COUNT]i64
	position := 0
	snapshot[position] = p1_count; position += 1
	for index := 0; index < 3; index += 1 { snapshot[position] = p1[index]; position += 1 }
	snapshot[position] = p2_count; position += 1
	for index := 0; index < 5; index += 1 { snapshot[position] = p2[index]; position += 1 }
	snapshot[position] = p3_count; position += 1
	for index := 0; index < 6; index += 1 { snapshot[position] = p3[index]; position += 1 }
	for index := 0; index < OUTPUT_COUNT; index += 1 {
		bits := u64(snapshot[index])
		for byte := 0; byte < 8; byte += 1 { output[index*8+byte] = u8(bits >> (byte*8)) }
	}
	return OUTPUT_BYTES
}
