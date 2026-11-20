module clarke_wright_savings_cvrp

fn reverse_route(mut routes []int, slot int, length int) {
	mut left := 0
	mut right := length - 1
	for left < right {
		routes[slot * 7 + left], routes[slot * 7 + right] = routes[slot * 7 + right], routes[slot * 7 + left]
		left++
		right--
	}
}

fn compare_routes(a []int, a_slot int, a_len int, b []int, b_slot int, b_len int) int {
	shared := if a_len < b_len { a_len } else { b_len }
	for i in 0 .. shared {
		av := a[a_slot * 7 + i]
		bv := b[b_slot * 7 + i]
		if av < bv { return -1 }
		if av > bv { return 1 }
	}
	if a_len < b_len { return -1 }
	if a_len > b_len { return 1 }
	return 0
}

fn put_word(mut output &u8, value i64) {
	bits := u64(value)
	for i in 0 .. 8 {
		unsafe { output[i] = u8((bits >> u64(8 * i)) & 255) }
	}
}

@[export: 'clarke_wright_savings_cvrp']
pub fn clarke_wright_savings_cvrp(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 74 { return -1 }
	unsafe {
		n0, cap0 := input[0], input[1]
		if n0 < 0 || n0 > 7 || cap0 < 1 || cap0 > 100 { return -1 }
		n, cap, width := int(n0), int(cap0), int(n0) + 1
		if length != usize(2 + n + width * width) { return -1 }
		mut demand := []i64{len: 8, init: 0}
		for c in 1 .. n + 1 {
			demand[c] = input[1 + c]
			if demand[c] < 1 || demand[c] > cap0 { return -1 }
		}
		mut distance := []i64{len: 64, init: 0}
		offset := 2 + n
		for i in 0 .. width { for j in 0 .. width {
			d := input[offset + i * width + j]
			if d < 0 || d > 1000 || (i == j && d != 0) { return -1 }
			distance[i * 8 + j] = d
		}}
		for i in 0 .. width { for j in i + 1 .. width {
			if distance[i * 8 + j] != distance[j * 8 + i] { return -1 }
		}}

		mut routes := []int{len: 49, init: 0}
		mut route_length := []int{len: 7, init: 0}
		mut load := []i64{len: 7, init: 0}
		mut active := []bool{len: 7, init: false}
		for r in 0 .. n { routes[r * 7] = r + 1; route_length[r] = 1; load[r] = demand[r + 1]; active[r] = true }
		mut savings := []i64{len: 21, init: 0}
		mut pair_i := []int{len: 21, init: 0}
		mut pair_j := []int{len: 21, init: 0}
		mut pair_count := 0
		for i in 1 .. n + 1 { for j in i + 1 .. n + 1 {
			savings[pair_count] = distance[i] + distance[j] - distance[i * 8 + j]
			pair_i[pair_count] = i
			pair_j[pair_count] = j
			pair_count++
		}}
		for i in 0 .. pair_count { for j in i + 1 .. pair_count {
			before := savings[j] > savings[i] || (savings[j] == savings[i] && (pair_i[j] < pair_i[i] || (pair_i[j] == pair_i[i] && pair_j[j] < pair_j[i])))
			if before {
				savings[i], savings[j] = savings[j], savings[i]
				pair_i[i], pair_i[j] = pair_i[j], pair_i[i]
				pair_j[i], pair_j[j] = pair_j[j], pair_j[i]
			}
		}}
		for p in 0 .. pair_count {
			if savings[p] <= 0 { break }
			mut ri, mut rj, mut pi, mut pj := -1, -1, -1, -1
			for r in 0 .. n { if active[r] { for at in 0 .. route_length[r] {
				if routes[r * 7 + at] == pair_i[p] { ri, pi = r, at }
				if routes[r * 7 + at] == pair_j[p] { rj, pj = r, at }
			}}}
			if ri == rj || ri < 0 || rj < 0 { continue }
			if (pi != 0 && pi != route_length[ri] - 1) || (pj != 0 && pj != route_length[rj] - 1) || load[ri] + load[rj] > cap { continue }
			if pi == 0 { reverse_route(mut routes, ri, route_length[ri]) }
			if pj == route_length[rj] - 1 { reverse_route(mut routes, rj, route_length[rj]) }
			old_length := route_length[ri]
			for at in 0 .. route_length[rj] { routes[ri * 7 + old_length + at] = routes[rj * 7 + at] }
			route_length[ri] += route_length[rj]
			load[ri] += load[rj]
			active[rj] = false
			route_length[rj] = 0
			load[rj] = 0
		}

		mut final_routes := []int{len: 49, init: 0}
		mut final_length := []int{len: 7, init: 0}
		mut count := 0
		for r in 0 .. n { if active[r] {
			mut reverse_first := false
			for at in 0 .. route_length[r] {
				a, b := routes[r * 7 + at], routes[r * 7 + route_length[r] - 1 - at]
				if a != b { reverse_first = a > b; break }
			}
			if reverse_first { reverse_route(mut routes, r, route_length[r]) }
			for at in 0 .. route_length[r] { final_routes[count * 7 + at] = routes[r * 7 + at] }
			final_length[count] = route_length[r]
			count++
		}}
		for i in 0 .. count { for j in i + 1 .. count {
			if compare_routes(final_routes, i, final_length[i], final_routes, j, final_length[j]) > 0 {
				for k in 0 .. 7 { final_routes[i * 7 + k], final_routes[j * 7 + k] = final_routes[j * 7 + k], final_routes[i * 7 + k] }
				final_length[i], final_length[j] = final_length[j], final_length[i]
			}
		}}
		mut words := []i64{len: 15, init: 0}
		mut word_count := 0
		words[word_count] = i64(count); word_count++
		for r in 0 .. count {
			words[word_count] = i64(final_length[r]); word_count++
			for at in 0 .. final_length[r] { words[word_count] = i64(final_routes[r * 7 + at]); word_count++ }
		}
		bytes := usize(word_count * 8)
		if output == nil || capacity < bytes { return -2 }
		for i in 0 .. word_count { put_word(mut output[i * 8], words[i]) }
		return i64(bytes)
	}
}
