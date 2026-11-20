package oa_speed_scaling

import "core:c"

MAX_JOBS :: 2
MAX_TIME :: 4
MAX_INPUT :: 8
MAX_OUTPUT :: 152
MAX_SEGMENTS :: 3

Rat :: struct { n: i64, d: i64 }
Segment :: struct { start: i64, finish: i64, speed_n: i64, speed_d: i64 }

gcd64 :: proc(a0, b0: i64) -> i64 {
	a, b := a0, b0
	for b != 0 { r := a % b; a = b; b = r }
	if a < 0 { return -a }
	return a
}
make_rat :: proc(n0, d0: i64) -> Rat {
	n, d := n0, d0
	if d < 0 { n = -n; d = -d }
	g := gcd64(n,d)
	return Rat{n/g,d/g}
}
rat_int :: proc(x: i64) -> Rat { return Rat{x,1} }
rat_add :: proc(a,b: Rat) -> Rat { return make_rat(a.n*b.d+b.n*a.d,a.d*b.d) }
rat_sub :: proc(a,b: Rat) -> Rat { return make_rat(a.n*b.d-b.n*a.d,a.d*b.d) }
rat_mul :: proc(a,b: Rat) -> Rat { return make_rat(a.n*b.n,a.d*b.d) }
rat_div :: proc(a,b: Rat) -> Rat { return make_rat(a.n*b.d,a.d*b.n) }
rat_cmp :: proc(a,b: Rat) -> int {
	left, right := a.n*b.d, b.n*a.d
	if left > right { return 1 }
	if left < right { return -1 }
	return 0
}
put64 :: proc(output: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[at+byte] = u8((bits>>(8*byte))&255) }
}
append_segment :: proc(segments: [^]Segment, count: ^int, start, finish: i64, speed: Rat) {
	if finish <= start || speed.n <= 0 do return
	if count^ > 0 && segments[count^-1].finish == start &&
		rat_cmp(speed,make_rat(segments[count^-1].speed_n,segments[count^-1].speed_d)) == 0 {
		segments[count^-1].finish = finish
		return
	}
	segments[count^] = Segment{start,finish,speed.n,speed.d}
	count^ += 1
}

@(export)
oa_speed_scaling :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 1 || n64 > MAX_JOBS do return -1
	n := int(n64)
	if length != c.size_t(1+3*n) do return -1
	release, deadline: [MAX_JOBS]i64
	work: [MAX_JOBS]i64
	remaining, completion: [MAX_JOBS]Rat
	completed: [MAX_JOBS]bool
	for j := 0; j < n; j += 1 {
		r, d, w := input[1+3*j], input[2+3*j], input[3+3*j]
		if r < 0 || r >= d || d > MAX_TIME || w < 1 || w > 4 do return -1
		release[j], deadline[j], work[j] = r, d, w
		remaining[j], completion[j] = rat_int(0), rat_int(0)
	}
	segments: [MAX_SEGMENTS]Segment
	segment_count := 0
	energy := rat_int(0)
	for now := i64(0); now <= MAX_TIME; now += 1 {
		has_arrival := false
		for j := 0; j < n; j += 1 { if release[j] == now { remaining[j] = rat_int(work[j]); has_arrival = true } }
		if !has_arrival do continue
		next_release := i64(MAX_TIME+1)
		for j := 0; j < n; j += 1 { if release[j] > now && release[j] < next_release { next_release = release[j] } }
		order: [MAX_JOBS]int
		used := 0
		for j := 0; j < n; j += 1 { if remaining[j].n > 0 && deadline[j] > now { order[used] = j; used += 1 } }
		for i := 1; i < used; i += 1 {
			value, k := order[i], i
			for k > 0 && (deadline[order[k-1]] > deadline[value] || (deadline[order[k-1]] == deadline[value] && order[k-1] > value)) {
				order[k] = order[k-1]; k -= 1
			}
			order[k] = value
		}
		left := now
		for used > 0 {
			prefix, best := rat_int(0), rat_int(0)
			best_count := 0
			for k := 1; k <= used; k += 1 {
				prefix = rat_add(prefix,remaining[order[k-1]])
				density := rat_div(prefix,rat_int(deadline[order[k-1]]-left))
				if best_count == 0 || rat_cmp(density,best) > 0 { best, best_count = density, k }
			}
			right := deadline[order[best_count-1]]
			stop := right
			if next_release < stop { stop = next_release }
			append_segment(&segments[0],&segment_count,left,stop,best)
			energy = rat_add(energy,rat_mul(rat_mul(rat_mul(best,best),best),rat_int(stop-left)))
			cursor, stop_rat := rat_int(left), rat_int(stop)
			for k := 0; k < best_count; k += 1 {
				j := order[k]
				finish := rat_add(cursor,rat_div(remaining[j],best))
				if rat_cmp(finish,stop_rat) <= 0 {
					completion[j], completed[j], remaining[j], cursor = finish, true, rat_int(0), finish
				} else {
					remaining[j] = rat_sub(remaining[j],rat_mul(best,rat_sub(stop_rat,cursor)))
					cursor = stop_rat
					break
				}
			}
			if stop < right do break
			for k := best_count; k < used; k += 1 { order[k-best_count] = order[k] }
			used -= best_count
			left = right
		}
	}
	for j := 0; j < n; j += 1 { if !completed[j] do return -1 }
	values: [MAX_OUTPUT/8]i64
	fields := 0
	values[fields] = i64(segment_count); fields += 1
	values[fields], values[fields+1] = energy.n, energy.d; fields += 2
	for s := 0; s < segment_count; s += 1 {
		values[fields], values[fields+1] = segments[s].start, segments[s].finish; fields += 2
		values[fields], values[fields+1] = segments[s].speed_n, segments[s].speed_d; fields += 2
	}
	for j := 0; j < n; j += 1 { values[fields], values[fields+1] = completion[j].n, completion[j].d; fields += 2 }
	bytes := 8*fields
	if output == nil || capacity < c.size_t(bytes) do return -2
	staged: [MAX_OUTPUT]u8
	for i := 0; i < fields; i += 1 { put64(&staged[0],8*i,values[i]) }
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
