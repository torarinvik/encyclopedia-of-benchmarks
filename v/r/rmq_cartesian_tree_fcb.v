module rmq_cartesian_tree_fcb

const n_max = 64
const q_max = 64
const e_max = 127
const b_max = 127
const levels_max = 8
const micro_max = 4

@[export: 'rmq_cartesian_tree_fcb']
pub fn rmq_cartesian_tree_fcb(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 195 { return -1 }
		if input[0] < 1 || input[0] > n_max || input[1] < 0 || input[1] > q_max { return -1 }
		n := int(input[0]); q := int(input[1]); qo := 2 + n
		if length != usize(qo + 2 * q) { return -1 }
		mut values := [n_max]i64{}
		for i in 0 .. n { values[i] = input[2+i]; if values[i] < -1000 || values[i] > 1000 { return -1 } }
		for i in 0 .. q { a := input[qo+2*i]; z := input[qo+2*i+1]; if a < 0 || a > z || z >= i64(n) { return -1 } }
		if output == nil || output_capacity < usize(q+1) { return -2 }
		mut left := [n_max]int{}; mut right := [n_max]int{}; mut parent := [n_max]int{}; mut mono := [n_max]int{}
		for i in 0 .. n { left[i] = -1; right[i] = -1; parent[i] = -1 }
		mut top := 0
		for i in 0 .. n { mut last := -1; for top > 0 && values[mono[top-1]] > values[i] { top--; last = mono[top] }
			if top > 0 { p := mono[top-1]; right[p] = i; parent[i] = p }
			if last >= 0 { left[i] = last; parent[last] = i }; mono[top] = i; top++ }
		mut root := 0; for parent[root] >= 0 { root++ }
		mut euler := [e_max]int{}; mut depth := [e_max]int{}; mut first := [n_max]int{}; mut node_depth := [n_max]int{}
		mut frame_node := [n_max]int{}; mut state := [n_max]int{}
		mut ec := 1; mut sp := 1; euler[0] = root; depth[0] = 0; first[root] = 0; node_depth[root] = 0; frame_node[0] = root
		for sp > 0 { slot := sp-1; v := frame_node[slot]
			if state[slot] == 0 { if left[v] >= 0 { c := left[v]; state[slot] = 1; node_depth[c] = node_depth[v]+1; first[c] = ec; euler[ec] = c; depth[ec] = node_depth[c]; ec++; frame_node[sp] = c; state[sp] = 0; sp++ }
				else if right[v] >= 0 { c := right[v]; state[slot] = 2; node_depth[c] = node_depth[v]+1; first[c] = ec; euler[ec] = c; depth[ec] = node_depth[c]; ec++; frame_node[sp] = c; state[sp] = 0; sp++ } else { sp-- } }
			else if state[slot] == 1 { euler[ec] = v; depth[ec] = node_depth[v]; ec++; if right[v] >= 0 { c := right[v]; state[slot] = 2; node_depth[c] = node_depth[v]+1; first[c] = ec; euler[ec] = c; depth[ec] = node_depth[c]; ec++; frame_node[sp] = c; state[sp] = 0; sp++ } else { sp-- } }
			else { euler[ec] = v; depth[ec] = node_depth[v]; ec++; sp-- } }
		mut lg := 0; mut x := ec; for x > 1 { x /= 2; lg++ }; mut bs := lg/2; if bs < 1 { bs = 1 }; blocks := (ec+bs-1)/bs
		mut micro := [8*micro_max*micro_max]int{}; mut pat := [b_max]int{}; mut logs := [b_max+1]int{}; mut macro := [levels_max*b_max]int{}
		for shape in 0 .. (1 << (bs-1)) { mut rel := [micro_max]int{}; for j in 0 .. (bs-1) { direction := if ((shape >> j)&1) != 0 {1} else {-1}; rel[j+1] = rel[j]+direction }
			for a in 0 .. bs { for z := a; z < bs; z++ { mut best := a; for k := a+1; k <= z; k++ { if rel[k] < rel[best] { best = k } }; micro[shape*16+a*4+z] = best } } }
		for b in 0 .. blocks { base := b*bs; end := min(ec,base+bs); mut best := base; for j := base; j+1 < end; j++ { if depth[j+1] > depth[j] { pat[b] |= 1 << (j-base) }; c := j+1; if depth[c] < depth[best] || (depth[c] == depth[best] && c < best) { best = c } }; macro[b] = best }
		for c in 2 .. (blocks+1) { logs[c] = logs[c/2]+1 }; mut levels := 1
		for (1 << levels) <= blocks && levels < levels_max { half := 1 << (levels-1); span := 2*half; for b in 0 .. (blocks-span+1) { a := macro[(levels-1)*b_max+b]; z := macro[(levels-1)*b_max+b+half]; macro[levels*b_max+b] = if depth[a] < depth[z] || (depth[a] == depth[z] && a < z) {a} else {z} }; levels++ }
		mut answers := [q_max]u8{}
		for i in 0 .. q { u := int(input[qo+2*i]); v := int(input[qo+2*i+1]); mut a := first[u]; mut z := first[v]; if a > z { t := a; a = z; z = t }; ba := a/bs; bz := z/bs; mut best := 0
			if ba == bz { best = ba*bs+micro[pat[ba]*16+(a%bs)*4+(z%bs)] } else { xa:=ba*bs; xz:=bz*bs; na:=min(bs,ec-xa); best=xa+micro[pat[ba]*16+(a%bs)*4+na-1]; rb:=xz+micro[pat[bz]*16+(z%bs)]; if depth[rb]<depth[best] || (depth[rb]==depth[best]&&rb<best){best=rb}; if bz>ba+1 {lo:=ba+1; hi:=bz-1; count:=hi-lo+1; k:=logs[count]; span:=1<<k; ca:=macro[k*b_max+lo]; cz:=macro[k*b_max+hi-span+1]; mid:=if depth[ca]<depth[cz]||(depth[ca]==depth[cz]&&ca<cz){ca}else{cz}; if depth[mid]<depth[best]||(depth[mid]==depth[best]&&mid<best){best=mid}} }
			answers[i] = u8(euler[best]) }
		output[0] = u8(q); for i in 0 .. q { output[i+1] = answers[i] }; return i64(q+1)
	}
}
