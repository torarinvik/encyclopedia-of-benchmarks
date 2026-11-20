// Clean-room McCreight radix priority-search-tree profile.
package priority_search_tree_three_sided_reporting

import "core:c"

MAX_N :: 8
MAX_Q :: 7
X_DOMAIN :: 32

@(export)
priority_search_tree_three_sided_reporting :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 48 do return -1
	n64 := input[0]
	q64 := input[1]
	if n64 < 0 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q || length != c.size_t(2 + 3 * n64 + 3 * q64) do return -1
	n := int(n64)
	q := int(q64)
	nx, ny, nl, nlo, nhi: [MAX_N]i64
	left, right: [MAX_N]int
	seen_x: [X_DOMAIN]bool
	seen_label: [MAX_N]bool
	for i := 0; i < MAX_N; i += 1 { left[i] = -1; right[i] = -1 }
	root := -1
	count := 0
	at := 2
	for _ in 0 ..< n {
		x, y, label := input[at], input[at + 1], input[at + 2]
		at += 3
		if x < 0 || x >= X_DOMAIN || y < -64 || y > 63 || label < 0 || label >= MAX_N do return -1
		if seen_x[int(x)] || seen_label[int(label)] do return -1
		seen_x[int(x)] = true
		seen_label[int(label)] = true
		px, py, pl := x, y, label
		if root < 0 {
			root = count
			count += 1
			nx[root] = px; ny[root] = py; nl[root] = pl; nlo[root] = 0; nhi[root] = X_DOMAIN
		} else {
			cur := root
			low := 0
			high := X_DOMAIN
			searching := true
			for searching {
				if py < ny[cur] {
					t := nx[cur]; nx[cur] = px; px = t
					t = ny[cur]; ny[cur] = py; py = t
					t = nl[cur]; nl[cur] = pl; pl = t
				}
				mid := (low + high) / 2
				if px < i64(mid) {
					if left[cur] < 0 {
						child := count; count += 1; left[cur] = child
						nx[child] = px; ny[child] = py; nl[child] = pl
						nlo[child] = i64(low); nhi[child] = i64(mid)
						searching = false
					} else { cur = left[cur]; high = mid }
				} else {
					if right[cur] < 0 {
						child := count; count += 1; right[cur] = child
						nx[child] = px; ny[child] = py; nl[child] = pl
						nlo[child] = i64(mid); nhi[child] = i64(high)
						searching = false
					} else { cur = right[cur]; low = mid }
				}
			}
		}
	}
	qx0, qx1, qy1: [MAX_Q]i64
	for qi := 0; qi < q; qi += 1 {
		qx0[qi], qx1[qi], qy1[qi] = input[at], input[at + 1], input[at + 2]
		at += 3
		if qx0[qi] < 0 || qx0[qi] > qx1[qi] || qx1[qi] >= X_DOMAIN || qy1[qi] < -64 || qy1[qi] > 63 do return -1
	}
	result: i64 = 0
	for qi := 0; qi < q; qi += 1 {
		mask: i64 = 0
		if root >= 0 {
			stack: [MAX_N]int
			top := 1
			stack[0] = root
			for top > 0 {
				top -= 1
				node := stack[top]
				if qx1[qi] < nlo[node] || qx0[qi] >= nhi[node] || ny[node] > qy1[qi] do continue
				if qx0[qi] <= nx[node] && nx[node] <= qx1[qi] { mask |= i64(1) << int(nl[node]) }
				if left[node] >= 0 { stack[top] = left[node]; top += 1 }
				if right[node] >= 0 { stack[top] = right[node]; top += 1 }
			}
		}
		result |= mask << (8 * qi)
	}
	return result
}
