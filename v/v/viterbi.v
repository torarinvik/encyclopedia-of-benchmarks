module viterbi

@[export: 'viterbi']
pub fn viterbi(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
	if length < 1 || length > 64 { return -1 }
	for i in 0 .. int(length) { if input[i] < 0 || input[i] > 2 { return -1 } }
	if capacity < length*8 { return -2 }
	mut tr := [4]f64{}
	tr[0] = 0.7; tr[1] = 0.3; tr[2] = 0.4; tr[3] = 0.6
	mut em := [6]f64{}
	em[0] = 0.5; em[1] = 0.4; em[2] = 0.1; em[3] = 0.1; em[4] = 0.3; em[5] = 0.6
	mut score := [2]f64{}
	score[0] = 0.6*em[input[0]]; score[1] = 0.4*em[3+input[0]]
	mut back := [128]int{}
	for t in 1 .. int(length) {
		mut next := [2]f64{}
		for s in 0 .. 2 {
			a := score[0]*tr[s]*em[s*3+int(input[t])]
			b := score[1]*tr[2+s]*em[s*3+int(input[t])]
			p := if b > a { 1 } else { 0 }
			back[t*2+s] = p
			next[s] = if p == 0 { a } else { b }
		}
		score = next
	}
	mut state := if score[1] > score[0] { 1 } else { 0 }
	mut path := [64]i64{}
	path[int(length)-1] = state
	for t := int(length)-1; t > 0; t-- { state = back[t*2+state]; path[t-1] = state }
	for i in 0 .. int(length) {
		value := u64(path[i])
		for b in 0 .. 8 { output[i*8+b] = u8((value >> (b*8)) & 0xff) }
	}
	return i64(length*8)
	}
}
