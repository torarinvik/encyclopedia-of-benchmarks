package viterbi

import "core:c"

@(export, link_name="viterbi")
viterbi :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
	if input == nil || length < 1 || length > 64 do return -1
	for i: uint = 0; i < length; i += 1 { if input[i] < 0 || input[i] > 2 do return -1 }
	if output == nil || capacity < length*8 do return -2
	tr := [4]f64{0.7,0.3,0.4,0.6}; em := [6]f64{0.5,0.4,0.1,0.1,0.3,0.6}
	score := [2]f64{0.6*em[input[0]],0.4*em[3+input[0]]}
	back: [128]uint
	for t: uint = 1; t < length; t += 1 {
		next: [2]f64
		for s: uint = 0; s < 2; s += 1 {
			a := score[0]*tr[s]*em[s*3+uint(input[t])]; b := score[1]*tr[2+s]*em[s*3+uint(input[t])]
			p: uint = 0; if b > a do p = 1
			back[t*2+s] = p; if p == 0 { next[s] = a } else { next[s] = b }
		}
		score = next
	}
	state: uint = 0; if score[1] > score[0] do state = 1
	path: [64]i64; path[length-1] = i64(state)
	t := length
	for t > 1 { t -= 1; state = back[t*2+state]; path[t-1] = i64(state) }
	for i: uint = 0; i < length; i += 1 { value := path[i]; for b: uint = 0; b < 8; b += 1 { output[i*8+b] = u8((u64(value) >> (b*8)) & 0xff) } }
	return i64(length*8)
}

main :: proc() {}
