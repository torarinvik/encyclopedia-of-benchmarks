module oa_speed_scaling

const max_jobs = 2
const max_time = 4
const max_input = 8
const max_output = 152
const max_segments = 3

struct Rat { n i64; d i64 }
struct Segment { start i64; finish i64; speed_n i64; speed_d i64 }

fn gcd64(a0 i64, b0 i64) i64 {
	mut a, b := a0, b0
	for b != 0 { r := a % b; a = b; b = r }
	if a < 0 { return -a }
	return a
}
fn make_rat(n0 i64, d0 i64) Rat {
	mut n, mut d := n0, d0
	if d < 0 { n = -n; d = -d }
	g := gcd64(n,d)
	return Rat{n: n/g, d: d/g}
}
fn rat_int(value i64) Rat { return Rat{n: value, d: 1} }
fn rat_add(a Rat,b Rat) Rat { return make_rat(a.n*b.d+b.n*a.d,a.d*b.d) }
fn rat_sub(a Rat,b Rat) Rat { return make_rat(a.n*b.d-b.n*a.d,a.d*b.d) }
fn rat_mul(a Rat,b Rat) Rat { return make_rat(a.n*b.n,a.d*b.d) }
fn rat_div(a Rat,b Rat) Rat { return make_rat(a.n*b.d,a.d*b.n) }
fn rat_cmp(a Rat,b Rat) int {
	left, right := a.n*b.d, b.n*a.d
	if left > right { return 1 }
	if left < right { return -1 }
	return 0
}
fn put64(output &u8, at int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[at+byte] = u8((bits >> (8*byte)) & 255) }
	}
}

@[export: 'oa_speed_scaling']
pub fn oa_speed_scaling(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64 := input[0]
		if n64 < 1 || n64 > i64(max_jobs) { return -1 }
		n := int(n64)
		if length != usize(1 + 3*n) { return -1 }
		mut release := [max_jobs]i64{init: 0}
		mut deadline := [max_jobs]i64{init: 0}
		mut work := [max_jobs]i64{init: 0}
		mut remaining := [max_jobs]Rat{init: Rat{n: 0, d: 1}}
		mut completion := [max_jobs]Rat{init: Rat{n: 0, d: 1}}
		mut completed := [max_jobs]bool{init: false}
		for j in 0 .. n {
			r, d, w := input[1+3*j], input[2+3*j], input[3+3*j]
			if r < 0 || r >= d || d > i64(max_time) || w < 1 || w > 4 { return -1 }
			release[j], deadline[j], work[j] = r, d, w
		}
		mut segments := [max_segments]Segment{init: Segment{}}
		mut segment_count := 0
		mut energy := rat_int(0)
		for now_index in 0 .. max_time+1 {
			now := i64(now_index)
			mut has_arrival := false
			for j in 0 .. n { if release[j] == now { remaining[j] = rat_int(work[j]); has_arrival = true } }
			if !has_arrival { continue }
			mut next_release := i64(max_time + 1)
			for j in 0 .. n { if release[j] > now && release[j] < next_release { next_release = release[j] } }
			mut order := [max_jobs]int{init: 0}
			mut used := 0
			for j in 0 .. n { if remaining[j].n > 0 && deadline[j] > now { order[used] = j; used++ } }
			for i in 1 .. used {
				value := order[i]
				mut k := i
				for k > 0 && (deadline[order[k-1]] > deadline[value] || (deadline[order[k-1]] == deadline[value] && order[k-1] > value)) {
					order[k] = order[k-1]; k--
				}
				order[k] = value
			}
			mut left := now
			for used > 0 {
				mut prefix := rat_int(0)
				mut best := rat_int(0)
				mut best_count := 0
				for k in 1 .. used+1 {
					prefix = rat_add(prefix,remaining[order[k-1]])
					density := rat_div(prefix,rat_int(deadline[order[k-1]]-left))
					if best_count == 0 || rat_cmp(density,best) > 0 { best, best_count = density, k }
				}
				right := deadline[order[best_count-1]]
				stop := if right < next_release { right } else { next_release }
				if stop > left {
					if segment_count > 0 && segments[segment_count-1].finish == left &&
						rat_cmp(best,make_rat(segments[segment_count-1].speed_n,segments[segment_count-1].speed_d)) == 0 {
						segments[segment_count-1].finish = stop
					} else {
						segments[segment_count] = Segment{start: left, finish: stop, speed_n: best.n, speed_d: best.d}
						segment_count++
					}
				}
				energy = rat_add(energy,rat_mul(rat_mul(rat_mul(best,best),best),rat_int(stop-left)))
				mut cursor := rat_int(left)
				stop_rat := rat_int(stop)
				for k in 0 .. best_count {
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
				if stop < right { break }
				for k in best_count .. used { order[k-best_count] = order[k] }
				used -= best_count
				left = right
			}
		}
		for j in 0 .. n { if !completed[j] { return -1 } }
		mut values := [max_output / 8]i64{init: 0}
		mut fields := 0
		values[fields] = i64(segment_count); fields++
		values[fields], values[fields+1] = energy.n, energy.d; fields += 2
		for s in 0 .. segment_count {
			values[fields], values[fields+1] = segments[s].start, segments[s].finish; fields += 2
			values[fields], values[fields+1] = segments[s].speed_n, segments[s].speed_d; fields += 2
		}
		for j in 0 .. n { values[fields], values[fields+1] = completion[j].n, completion[j].d; fields += 2 }
		output_bytes := 8*fields
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [max_output]u8{init: 0}
		for i in 0 .. fields { put64(&staged[0],8*i,values[i]) }
		for i in 0 .. output_bytes { output[i] = staged[i] }
		return i64(output_bytes)
	}
}
