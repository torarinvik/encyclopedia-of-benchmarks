// Clean-room port of SIM's documented first-best local affine score.
package ptrdist_sim_local_affine_alignment

import "core:c"

MAX_LEN :: 64
STRIDE :: 65
CELLS :: STRIDE * STRIDE

@(export)
ptrdist_sim_local_affine_alignment :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 130 || input[0] < 1 || input[0] > MAX_LEN do return -1
	left := int(input[0])
	right_pos := 1 + left
	if right_pos >= int(length) || input[right_pos] < 1 || input[right_pos] > MAX_LEN do return -1
	right := int(input[right_pos])
	if int(length) != right_pos + 1 + right do return -1
	for i in 0..<left {
		c0 := input[1+i]
		if c0 != 65 && c0 != 67 && c0 != 71 && c0 != 84 do return -1
	}
	for j in 0..<right {
		c0 := input[right_pos+1+j]
		if c0 != 65 && c0 != 67 && c0 != 71 && c0 != 84 do return -1
	}
	h: [CELLS]i64 = {}
	d: [CELLS]i64 = {}
	f: [CELLS]i64 = {}
	for j in 1..=right do d[j] = -60
	for i in 1..=left do f[i*STRIDE] = -60
	best := i64(0)
	for i in 1..=left {
		for j in 1..=right {
			p := i*STRIDE+j
			d_open, d_extend := h[p-STRIDE]-62, d[p-STRIDE]-2
			if d_open > d_extend { d[p] = d_open } else { d[p] = d_extend }
			f_open, f_extend := h[p-1]-62, f[p-1]-2
			if f_open > f_extend { f[p] = f_open } else { f[p] = f_extend }
			score := h[p-STRIDE-1] - 10
			if input[i] == input[right_pos+j] { score += 20 }
			if score < 0 do score = 0
			if d[p] > score do score = d[p]
			if f[p] > score do score = f[p]
			h[p] = score
			if score > best do best = score
		}
	}
	return best
}
