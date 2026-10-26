// Clean-room port of SIM's documented first-best local affine score.
module ptrdist_sim_local_affine_alignment

const stride = 65
const cells = stride * stride

@[export: 'ptrdist_sim_local_affine_alignment']
pub fn ptrdist_sim_local_affine_alignment(input &i64, length usize) i64 {
	if input == unsafe { nil } || length < 4 || length > 130 || input[0] < 1 || input[0] > 64 { return -1 }
	left := int(input[0])
	right_pos := 1 + left
	if right_pos >= int(length) || input[right_pos] < 1 || input[right_pos] > 64 { return -1 }
	right := int(input[right_pos])
	if int(length) != right_pos + 1 + right { return -1 }
	for i in 0 .. left {
		c := input[1+i]
		if c != 65 && c != 67 && c != 71 && c != 84 { return -1 }
	}
	for j in 0 .. right {
		c := input[right_pos+1+j]
		if c != 65 && c != 67 && c != 71 && c != 84 { return -1 }
	}
	mut h := []i64{len: cells}
	mut d := []i64{len: cells}
	mut f := []i64{len: cells}
	for j in 1 .. right+1 { d[j] = -60 }
	for i in 1 .. left+1 { f[i*stride] = -60 }
	mut best := i64(0)
	for i in 1 .. left+1 {
		for j in 1 .. right+1 {
			p := i*stride+j
			d_open := h[p-stride]-62
			d_extend := d[p-stride]-2
			d[p] = if d_open > d_extend { d_open } else { d_extend }
			f_open := h[p-1]-62
			f_extend := f[p-1]-2
			f[p] = if f_open > f_extend { f_open } else { f_extend }
			mut score := h[p-stride-1] + if input[i] == input[right_pos+j] { i64(10) } else { i64(-10) }
			if score < 0 { score = 0 }
			if d[p] > score { score = d[p] }
			if f[p] > score { score = f[p] }
			h[p] = score
			if score > best { best = score }
		}
	}
	return best
}
