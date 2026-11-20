package c

import "core:c"

Saving :: struct { value: i64, i: int, j: int }

reverse_route :: proc(routes: []int, slot, length: int) {
	left, right := 0, length-1
	for left < right {
		routes[slot*7+left], routes[slot*7+right] = routes[slot*7+right], routes[slot*7+left]
		left += 1; right -= 1
	}
}

compare_routes :: proc(a: []int, an: int, b: []int, bn: int) -> int {
	shared := min(an, bn)
	for i := 0; i < shared; i += 1 {
		if a[i] < b[i] do return -1
		if a[i] > b[i] do return 1
	}
	if an < bn do return -1
	if an > bn do return 1
	return 0
}

put_i64 :: proc(out: [^]u8, value: i64) {
	bits := cast(u64)value
	for i := 0; i < 8; i += 1 { out[i] = u8((bits >> u64(8*i)) & 255) }
}

clarke_wright_savings_cvrp :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 74 do return -1
	n0, cap0 := input[0], input[1]
	if n0 < 0 || n0 > 7 || cap0 < 1 || cap0 > 100 do return -1
	n, vehicle_capacity := int(n0), int(cap0)
	width := n+1
	if length != c.size_t(2+n+width*width) do return -1
	var demand: [8]i64
	for customer := 1; customer <= n; customer += 1 {
		demand[customer] = input[1+customer]
		if demand[customer] < 1 || demand[customer] > cap0 do return -1
	}
	var distance: [64]i64
	offset := 2+n
	for i := 0; i < width; i += 1 { for j := 0; j < width; j += 1 {
		d := input[offset+i*width+j]
		if d < 0 || d > 1000 || (i == j && d != 0) do return -1
		distance[i*8+j] = d
	}}
	for i := 0; i < width; i += 1 { for j := i+1; j < width; j += 1 {
		if distance[i*8+j] != distance[j*8+i] do return -1
	}}

	var routes: [49]int
	var route_length: [7]int
	var load: [7]i64
	var active: [7]bool
	for r := 0; r < n; r += 1 { routes[r*7] = r+1; route_length[r] = 1; load[r] = demand[r+1]; active[r] = true }
	var pairs: [21]Saving
	pair_count := 0
	for i := 1; i <= n; i += 1 { for j := i+1; j <= n; j += 1 {
		pairs[pair_count] = Saving{distance[i]+distance[j]-distance[i*8+j], i, j}
		pair_count += 1
	}}
	for i := 0; i < pair_count; i += 1 { for j := i+1; j < pair_count; j += 1 {
		a, b := pairs[i], pairs[j]
		if b.value > a.value || (b.value == a.value && (b.i < a.i || (b.i == a.i && b.j < a.j))) {
			pairs[i], pairs[j] = pairs[j], pairs[i]
		}
	}}
	for p := 0; p < pair_count; p += 1 {
		if pairs[p].value <= 0 do break
		ri, rj, pi, pj := -1, -1, -1, -1
		for r := 0; r < n; r += 1 { if active[r] { for at := 0; at < route_length[r]; at += 1 {
			if routes[r*7+at] == pairs[p].i { ri = r; pi = at }
			if routes[r*7+at] == pairs[p].j { rj = r; pj = at }
		}}}
		if ri == rj || ri < 0 || rj < 0 do continue
		if (pi != 0 && pi != route_length[ri]-1) || (pj != 0 && pj != route_length[rj]-1) || load[ri]+load[rj] > vehicle_capacity do continue
		if pi == 0 { reverse_route(routes[:], ri, route_length[ri]) }
		if pj == route_length[rj]-1 { reverse_route(routes[:], rj, route_length[rj]) }
		old_length := route_length[ri]
		for at := 0; at < route_length[rj]; at += 1 { routes[ri*7+old_length+at] = routes[rj*7+at] }
		route_length[ri] += route_length[rj]; load[ri] += load[rj]
		active[rj] = false; route_length[rj] = 0; load[rj] = 0
	}

	var final_routes: [49]int
	var final_length: [7]int
	count := 0
	for r := 0; r < n; r += 1 { if active[r] {
		reverse_first := false
		for at := 0; at < route_length[r]; at += 1 { a,b := routes[r*7+at],routes[r*7+route_length[r]-1-at];if a!=b {reverse_first=a>b;break} }
		if reverse_first { reverse_route(routes[:], r, route_length[r]) }
		for at := 0; at < route_length[r]; at += 1 { final_routes[count*7+at] = routes[r*7+at] }
		final_length[count] = route_length[r]; count += 1
	}}
	for i := 0; i < count; i += 1 { for j := i+1; j < count; j += 1 {
		if compare_routes(final_routes[i*7:i*7+final_length[i]], final_length[i], final_routes[j*7:j*7+final_length[j]], final_length[j]) > 0 {
			for k := 0; k < 7; k += 1 { final_routes[i*7+k],final_routes[j*7+k]=final_routes[j*7+k],final_routes[i*7+k] }
			final_length[i],final_length[j]=final_length[j],final_length[i]
		}
	}}
	var words: [15]i64
	word_count := 0; words[word_count] = i64(count); word_count += 1
	for r := 0; r < count; r += 1 { words[word_count] = i64(final_length[r]);word_count += 1;for at:=0;at<final_length[r];at+=1{words[word_count]=i64(final_routes[r*7+at]);word_count+=1} }
	bytes := word_count*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < word_count; i += 1 { put_i64(output+c.size_t(i*8), words[i]) }
	return i64(bytes)
}
