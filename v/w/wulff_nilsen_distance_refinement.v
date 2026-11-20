module main

const wn_scale = i64(86093442)
const wn_inf = i64(0x1000000000000000)
const wn_max_n = 8
const wn_max_input = usize(93)

fn wn_even_index(x int, threshold i64, nearest [32]int, distance [64]i64) int {
	if distance[x * wn_max_n + nearest[2 * wn_max_n + x]] <= threshold { return 2 }
	return 0
}

fn wn_refine_further(u int, v int, iu int, nearest [32]int, bunch [64]bool) bool {
	if iu < 2 { return false }
	return bunch[v * wn_max_n + nearest[u]] || bunch[u * wn_max_n + nearest[wn_max_n + v]] ||
		bunch[v * wn_max_n + nearest[iu * wn_max_n + u]] || bunch[u * wn_max_n + nearest[(iu + 1) * wn_max_n + v]]
}

@[export: 'wulff_nilsen_distance_refinement']
pub fn wulff_nilsen_distance_refinement(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 8 || length > wn_max_input { return -1 }
		n0 := input[0]; m0 := input[1]
		if n0 < 2 || n0 > wn_max_n || m0 < 0 || m0 > 28 { return -1 }
		n := int(n0); m := int(m0)
		if length != usize(8 + 3 * m) { return -1 }
		full := (i64(1) << n) - 1
		mut masks := [3]i64{}
		for i in 0 .. 3 { masks[i] = input[2 + i]; if masks[i] <= 0 || (masks[i] & ~full) != 0 { return -1 } }
		if (masks[1] & ~masks[0]) != 0 || (masks[2] & ~masks[1]) != 0 { return -1 }
		mut distance := [64]i64{}
		for u in 0 .. n { for v in 0 .. n { distance[u * wn_max_n + v] = if u == v { 0 } else { wn_inf } } }
		mut prev_u := -1; mut prev_v := -1
		for e in 0 .. m {
			at := 5 + 3 * e; u0 := input[at]; v0 := input[at + 1]; weight := input[at + 2]
			if u0 < 0 || u0 >= n0 || v0 <= u0 || v0 >= n0 || weight < wn_scale || weight > 100 * wn_scale || weight % wn_scale != 0 { return -1 }
			u := int(u0); v := int(v0)
			if u < prev_u || (u == prev_u && v <= prev_v) { return -1 }
			prev_u = u; prev_v = v; distance[u * wn_max_n + v] = weight; distance[v * wn_max_n + u] = weight
		}
		q := 5 + 3 * m; source0 := input[q]; target0 := input[q + 1]; estimate := input[q + 2]
		if source0 < 0 || source0 >= n0 || target0 < 0 || target0 >= n0 || source0 == target0 || estimate <= 0 || estimate % wn_scale != 0 { return -1 }
		source := int(source0); target := int(target0)
		for mid in 0 .. n { for u in 0 .. n { if distance[u * wn_max_n + mid] == wn_inf { continue }; for v in 0 .. n { candidate := distance[u * wn_max_n + mid] + distance[mid * wn_max_n + v]; if candidate < distance[u * wn_max_n + v] { distance[u * wn_max_n + v] = candidate } } } }
		for u in 0 .. n { for v in 0 .. n { if distance[u * wn_max_n + v] == wn_inf { return -1 } } }
		if estimate < distance[source * wn_max_n + target] || estimate > 768 * distance[source * wn_max_n + target] { return -1 }
		mut nearest := [32]int{}
		for x in 0 .. n {
			nearest[x] = x
			for level in 1 .. 4 {
				mut best := -1
				for y in 0 .. n { if (masks[level - 1] >> y) & 1 != 0 && (best < 0 || distance[x * wn_max_n + y] < distance[x * wn_max_n + best] || (distance[x * wn_max_n + y] == distance[x * wn_max_n + best] && y < best)) { best = y } }
				nearest[level * wn_max_n + x] = best
			}
		}
		layers := [5]i64{full, masks[0], masks[1], masks[2], 0}
		mut bunch := [64]bool{}
		for center in 0 .. n { for level in 0 .. 4 {
			mut boundary := wn_inf
			for y in 0 .. n { if (layers[level + 1] >> y) & 1 != 0 && distance[center * wn_max_n + y] < boundary { boundary = distance[center * wn_max_n + y] } }
			for y in 0 .. n { if (layers[level] >> y) & 1 != 0 && (layers[level + 1] >> y) & 1 == 0 && distance[center * wn_max_n + y] < boundary { bunch[center * wn_max_n + y] = true } }
		} }
		mut value := estimate; mut iu := wn_even_index(source, value, nearest, distance)
		if !wn_refine_further(source, target, iu, nearest, bunch) { return value }
		mut iteration := 0
		for iteration <= 15 && wn_refine_further(source, target, iu, nearest, bunch) { value = 2 * value / 3; iu = wn_even_index(source, value, nearest, distance); iteration++ }
		upper := wn_even_index(source, 3 * value / 2, nearest, distance)
		if upper < 2 { return -1 }
		mut pivot := nearest[source]
		if bunch[target * wn_max_n + pivot] { return distance[source * wn_max_n + pivot] + distance[target * wn_max_n + pivot] }
		pivot = nearest[wn_max_n + target]
		if bunch[source * wn_max_n + pivot] { return distance[source * wn_max_n + pivot] + distance[target * wn_max_n + pivot] }
		pivot = nearest[upper * wn_max_n + source]
		if bunch[target * wn_max_n + pivot] { return distance[source * wn_max_n + pivot] + distance[target * wn_max_n + pivot] }
		pivot = nearest[(upper + 1) * wn_max_n + target]
		return distance[source * wn_max_n + pivot] + distance[target * wn_max_n + pivot]
	}
}
