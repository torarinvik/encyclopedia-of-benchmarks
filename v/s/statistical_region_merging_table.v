fn srm_root(mut parent [36]int, start int) int {
	mut x := start
	for parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
	return x
}

@[export: 'statistical_region_merging_table']
pub fn statistical_region_merging_table(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 74 { return -1 }
		if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 { return -1 }
		width := int(input[1]); n := int(input[0]) * width
		if length != usize(2+2*n) { return -1 }
		for i in 0 .. n { if input[2+i] < 0 || input[2+i] > 65535 || input[2+n+i] < 0 || input[2+n+i] > 255 { return -1 } }
		mut parent := [36]int{}
		mut sizes := [36]int{}
		mut minimum := [36]int{}
		mut sums := [36]i64{}
		for i in 0 .. n { parent[i] = i; sizes[i] = 1; minimum[i] = i; sums[i] = input[2+n+i] }
		for diff in 0 .. 256 {
			for p in 0 .. n {
				mut neighbors := [2]int{}
				mut count := 0
				if p % width + 1 < width { neighbors[count] = p+1; count++ }
				if p + width < n { neighbors[count] = p+width; count++ }
				for k in 0 .. count {
					q := neighbors[k]
					mut d := input[2+n+p] - input[2+n+q]
					if d < 0 { d = -d }
					if d != i64(diff) { continue }
					mut a := srm_root(mut parent, p)
					mut b := srm_root(mut parent, q)
					if a == b { continue }
					na := i64(sizes[a]); nb := i64(sizes[b])
					delta := sums[a]*nb - sums[b]*na
					bound := input[1+sizes[a]] + input[1+sizes[b]]
					if delta*delta > bound*na*na*nb*nb { continue }
					if sizes[a] < sizes[b] { t := a; a = b; b = t }
					parent[b] = a; sizes[a] += sizes[b]; sums[a] += sums[b]
					if minimum[b] < minimum[a] { minimum[a] = minimum[b] }
				}
			}
		}
		if output == nil || capacity < usize(n) { return -2 }
		for i in 0 .. n { output[i] = u8(minimum[srm_root(mut parent, i)]) }
		return i64(n)
	}
}
