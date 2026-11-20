// Clean-room McCreight radix priority-search-tree profile.
const max_n = 8
const max_q = 7
const x_domain = 32

@[export: 'priority_search_tree_three_sided_reporting']
pub fn priority_search_tree_three_sided_reporting(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 48 { return -1 }
		n64 := input[0]
		q64 := input[1]
		if n64 < 0 || n64 > max_n || q64 < 0 || q64 > max_q || length != usize(2 + 3 * n64 + 3 * q64) { return -1 }
		n := int(n64)
		q := int(q64)
		mut nx := []i64{len: max_n, init: 0}
		mut ny := []i64{len: max_n, init: 0}
		mut nl := []i64{len: max_n, init: 0}
		mut nlo := []i64{len: max_n, init: 0}
		mut nhi := []i64{len: max_n, init: 0}
		mut left := []int{len: max_n, init: -1}
		mut right := []int{len: max_n, init: -1}
		mut seen_x := []bool{len: x_domain, init: false}
		mut seen_label := []bool{len: max_n, init: false}
		mut root := -1
		mut count := 0
		mut at := 2
		for _ in 0 .. n {
			x := input[at]
			y := input[at + 1]
			label := input[at + 2]
			at += 3
			if x < 0 || x >= x_domain || y < -64 || y > 63 || label < 0 || label >= max_n { return -1 }
			if seen_x[int(x)] || seen_label[int(label)] { return -1 }
			seen_x[int(x)] = true
			seen_label[int(label)] = true
			mut px := x
			mut py := y
			mut pl := label
			if root < 0 {
				root = count
				count++
				nx[root] = px; ny[root] = py; nl[root] = pl; nlo[root] = 0; nhi[root] = x_domain
			} else {
				mut cur := root
				mut low := 0
				mut high := x_domain
				mut searching := true
				for searching {
					if py < ny[cur] {
						t := nx[cur]; nx[cur] = px; px = t
						t = ny[cur]; ny[cur] = py; py = t
						t = nl[cur]; nl[cur] = pl; pl = t
					}
					mid := (low + high) / 2
					if px < i64(mid) {
						if left[cur] < 0 {
							child := count; count++; left[cur] = child
							nx[child] = px; ny[child] = py; nl[child] = pl; nlo[child] = i64(low); nhi[child] = i64(mid)
							searching = false
						} else { cur = left[cur]; high = mid }
					} else {
						if right[cur] < 0 {
							child := count; count++; right[cur] = child
							nx[child] = px; ny[child] = py; nl[child] = pl; nlo[child] = i64(mid); nhi[child] = i64(high)
							searching = false
						} else { cur = right[cur]; low = mid }
					}
				}
			}
		}
		mut qx0 := []i64{len: max_q, init: 0}
		mut qx1 := []i64{len: max_q, init: 0}
		mut qy1 := []i64{len: max_q, init: 0}
		for qi in 0 .. q {
			qx0[qi] = input[at]; qx1[qi] = input[at + 1]; qy1[qi] = input[at + 2]; at += 3
			if qx0[qi] < 0 || qx0[qi] > qx1[qi] || qx1[qi] >= x_domain || qy1[qi] < -64 || qy1[qi] > 63 { return -1 }
		}
		mut result := i64(0)
		for qi in 0 .. q {
			mut mask := i64(0)
			if root >= 0 {
				mut stack := []int{len: max_n, init: 0}
				mut top := 1
				stack[0] = root
				for top > 0 {
					top--
					node := stack[top]
					if qx1[qi] < nlo[node] || qx0[qi] >= nhi[node] || ny[node] > qy1[qi] { continue }
					if qx0[qi] <= nx[node] && nx[node] <= qx1[qi] { mask |= i64(1) << int(nl[node]) }
					if left[node] >= 0 { stack[top] = left[node]; top++ }
					if right[node] >= 0 { stack[top] = right[node]; top++ }
				}
			}
			result |= mask << (8 * qi)
		}
		return result
	}
}
