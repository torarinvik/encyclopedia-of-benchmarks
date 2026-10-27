package felsenstein_substitution_likelihood

import "core:c"

put_i64 :: proc(out: [^]u8, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[b] = u8((bits >> u64(8*b)) & 255) }
}

felsenstein_substitution_likelihood :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 38 do return -1
	n := input[0]
	if n < 1 || n > 8 do return -1
	stack: [8][2]i64
	sp := 0; leaves := 0; joins := 0; edges := 0; at := 1
	for at < int(length) {
		tag := input[at]; at += 1
		if tag == 0 {
			if at >= int(length) || input[at] < 0 || input[at] > 1 || sp >= 8 do return -1
			if input[at] == 0 { stack[sp] = [2]i64{1,0} } else { stack[sp] = [2]i64{0,1} }
			at += 1; sp += 1; leaves += 1
		} else if tag == 1 {
			if at+2 > int(length) || sp < 2 || input[at] < 0 || input[at] > 1 || input[at+1] < 0 || input[at+1] > 1 do return -1
			lm := input[at]; rm := input[at+1]; at += 2
			left := stack[sp-2]; right := stack[sp-1]; next: [2]i64
			for parent := 0; parent < 2; parent += 1 {
				l := left[parent]; r := right[parent]
				if lm == 0 { l *= 4 } else { l = 3*l + left[1-parent] }
				if rm == 0 { r *= 4 } else { r = 3*r + right[1-parent] }
				next[parent] = l*r
			}
			stack[sp-2] = next; sp -= 1; joins += 1; edges += 2
		} else { return -1 }
	}
	if leaves != n || joins != n-1 || sp != 1 || edges != 2*n-2 do return -1
	shift := 29-2*edges
	if shift < 0 do return -1
	scaled := (stack[0][0]+stack[0][1]) << shift
	if output == nil || capacity < 8 do return -2
	put_i64(output,scaled)
	return 8
}
