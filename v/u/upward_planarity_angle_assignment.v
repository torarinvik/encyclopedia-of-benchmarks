// Clean-room fixed-embedding angle-assignment flow profile, DOI 653.
module upward_planarity_angle_assignment

const nmax = 8
const mmax = 18
const fmax = 12

fn put64(mut output &u8, index int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[index * 8 + b] = u8((bits >> (8 * b)) & 255) } }
}

fn augment(t int, ns int, slots []int, terms []int, incidence [][]bool, mut owner []int, mut assigned []int, mut seen []bool) bool {
	for s in 0 .. ns {
		f := slots[s]
		if incidence[terms[t]][f] && !seen[s] {
			seen[s] = true
			if owner[s] < 0 || augment(owner[s], ns, slots, terms, incidence, mut owner, mut assigned, mut seen) {
				owner[s] = t
				assigned[t] = s
				return true
			}
		}
	}
	return false
}

fn suffix_match(first int, r int, f int, caps []int, terms []int, incidence [][]bool) bool {
	mut slots := []int{len: nmax, init: 0}
	mut ns := 0
	for face := 0; face < f; face++ { for _ in 0 .. caps[face] { slots[ns] = face; ns++ } }
	mut owner := []int{len: nmax, init: -1}; mut assigned := []int{len: nmax, init: -1}
	for t := first; t < r; t++ { mut seen := []bool{len: nmax, init: false}; if !augment(t, ns, slots, terms, incidence, mut owner, mut assigned, mut seen) { return false } }
	return true
}

@[export: 'upward_planarity_angle_assignment']
pub fn upward_planarity_angle_assignment(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > 124 { return -1 }
	unsafe {
		nv := input[0]; mv := input[1]; fv := input[2]; ov := input[3]
		if nv < 2 || nv > nmax || mv < 1 || mv > mmax || fv < 1 || fv > fmax || ov < 0 || ov >= fv || length != usize(4 + 6 * mv + fv) { return -1 }
		n := int(nv); m := int(mv); f := int(fv); outer := int(ov)
		mut adj := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}
		mut directed := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}
		mut indeg := []int{len: nmax, init: 0}; mut eu := []int{len: mmax, init: 0}; mut ev := []int{len: mmax, init: 0}
		for i := 0; i < m; i++ {
			u64 := input[4 + 2 * i]; v64 := input[5 + 2 * i]
			if u64 < 0 || u64 >= nv || v64 < 0 || v64 >= nv || u64 == v64 { return -1 }
			u := int(u64); v := int(v64)
			if i > 0 && (eu[i - 1] > u || (eu[i - 1] == u && ev[i - 1] >= v)) { return -1 }
			for j := 0; j < i; j++ { if (eu[j] == u && ev[j] == v) || (eu[j] == v && ev[j] == u) { return -1 } }
			eu[i] = u; ev[i] = v; adj[u][v] = true; adj[v][u] = true; directed[u][v] = true; indeg[v]++
		}
		mut wl := []int{len: fmax, init: 0}; mut wu := []int{len: 2 * mmax, init: 0}; mut wv := []int{len: 2 * mmax, init: 0}
		mut darts := [][]bool{len: nmax, init: []bool{len: nmax, init: false}}; mut cursor := 4 + 2 * m; mut total := 0
		for j := 0; j < f; j++ {
			k64 := input[cursor]; cursor++
			if k64 < 1 || k64 > 2 * m || total + int(k64) > 2 * m { return -1 }
			k := int(k64); wl[j] = k
			for z := 0; z < k; z++ {
				u64 := input[cursor]; v64 := input[cursor + 1]; cursor += 2
				if u64 < 0 || u64 >= nv || v64 < 0 || v64 >= nv { return -1 }
				u := int(u64); v := int(v64)
				if !adj[u][v] || darts[u][v] { return -1 }
				darts[u][v] = true; wu[total] = u; wv[total] = v; total++
			}
		}
		if cursor != int(length) || total != 2 * m || n - m + f != 2 { return -1 }
		for i := 0; i < m; i++ { if !darts[eu[i]][ev[i]] || !darts[ev[i]][eu[i]] { return -1 } }
		mut succ := [][]int{len: nmax, init: []int{len: nmax, init: -1}}
		mut corner := [][]int{len: fmax, init: []int{len: nmax, init: -1}}
		mut incident := [][]bool{len: nmax, init: []bool{len: fmax, init: false}}
		mut sw := [][]int{len: fmax, init: []int{len: 2, init: 0}}; cursor = 0
		for j := 0; j < f; j++ {
			base := cursor; k := wl[j]
			for i := 0; i < k; i++ {
				u := wu[cursor]; v := wv[cursor]; w := wv[base + (i + 1) % k]
				if v != wu[base + (i + 1) % k] || succ[v][u] >= 0 { return -1 }
				succ[v][u] = w; if corner[j][v] < 0 { corner[j][v] = i }; incident[v][j] = true
				if directed[v][u] && directed[v][w] { sw[j][0]++ }; if !directed[v][u] && !directed[v][w] { sw[j][1]++ }; cursor++
			}
		}
		mut vis := []bool{len: nmax, init: false}; mut q := []int{len: nmax, init: 0}; mut head := 0; mut tail := 1; q[0] = 0; vis[0] = true
		for head < tail { u := q[head]; head++; for v := 0; v < n; v++ { if adj[u][v] && !vis[v] { vis[v] = true; q[tail] = v; tail++ } } }
		for v := 0; v < n; v++ { if !vis[v] { return -1 } }
		mut deg := indeg.clone(); head = 0; tail = 0; for v := 0; v < n; v++ { if deg[v] == 0 { q[tail] = v; tail++ } }
		mut removed := 0; for head < tail { u := q[head]; head++; removed++; for v := 0; v < n; v++ { if directed[u][v] { deg[v]--; if deg[v] == 0 { q[tail] = v; tail++ } } } }; if removed != n { return -1 }
		for v := 0; v < n; v++ { mut d := 0; for u := 0; u < n; u++ { if adj[v][u] { d++ } }; if d > 0 { mut start := -1; for u := 0; u < n; u++ { if adj[v][u] { if succ[v][u] < 0 { return -1 }; start = u } }; mut cur := start; mut cnt := 0; mut tr := 0; for { cnt++; if cnt > d { return -1 }; nxt := succ[v][cur]; if directed[v][cur] != directed[v][nxt] { tr++ }; cur = nxt; if cur == start { break } }; if cnt != d || (tr != 0 && tr != 2) { return -1 } } }
		mut caps := []int{len: fmax, init: 0}; mut sum := 0; mut feasible := true; for j := 0; j < f; j++ { if sw[j][0] != sw[j][1] { return -1 }; caps[j] = sw[j][0] + if j == outer { 1 } else { -1 }; if caps[j] < 0 { feasible = false }; sum += caps[j] }
		mut terms := []int{len: nmax, init: 0}; mut r := 0; for v := 0; v < n; v++ { mut od := 0; for u := 0; u < n; u++ { if directed[v][u] { od++ } }; if indeg[v] == 0 || od == 0 { terms[r] = v; r++ } }; if sum != r { feasible = false }
		if unsafe { output == nil } || output_capacity < usize(8 * (2 + 3 * r)) { return -2 }
		mut chosen := []int{len: nmax, init: -1}; mut ok := feasible
		for i := 0; i < r; i++ { if !ok { break }; mut found := false; for face := 0; face < f; face++ { if incident[terms[i]][face] && caps[face] > 0 { caps[face]--; if suffix_match(i + 1, r, f, caps, terms, incident) { chosen[i] = face; found = true; break }; caps[face]++ } }; if !found { ok = false } }
		mut words := []i64{len: 26, init: 0}; words[0] = if ok { 1 } else { 0 }; words[1] = i64(r); mut z := 2
		for i := 0; i < r; i++ { if ok { face := chosen[i]; words[z] = i64(terms[i]); words[z + 1] = i64(face); words[z + 2] = i64(corner[face][terms[i]]) } else { words[z] = -1; words[z + 1] = -1; words[z + 2] = -1 }; z += 3 }
		for i := 0; i < z; i++ { put64(mut output, i, words[i]) }; return i64(z * 8)
	}
}
