package optimistic_flow_control_updates

import "core:c"

MAX_N :: 3
MAX_L :: 4
MAX_INPUT :: 20
MAX_OUTPUT :: 48
MAX_UPDATES :: 6
SCALE :: i64(46656)

gcd64 :: proc(a0, b0: i64) -> i64 {
	a, b := a0, b0
	for b != 0 { r := a%b; a = b; b = r }
	return a
}
put64 :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[position+byte] = u8(bits&255); bits >>= 8 }
}

@(export)
optimistic_flow_control_updates :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 7 || length > MAX_INPUT do return -1
	n64, l64, mode64, q64 := input[0], input[1], input[2], input[3]
	if n64 < 2 || n64 > MAX_N || l64 < 1 || l64 > MAX_L || mode64 < 0 || mode64 > 3 || q64 < 1 || q64 > MAX_UPDATES do return -1
	n, links, mode, updates := int(n64), int(l64), int(mode64), int(q64)
	if length != c.size_t(4+links+n*links) do return -1
	cap: [MAX_L]i64
	path: [MAX_N][MAX_L]bool
	rate: [MAX_N]i64
	for e := 0; e < links; e += 1 { cap[e] = input[4+e]; if cap[e] < 1 || cap[e] > 16 do return -1 }
	for s := 0; s < n; s += 1 {
		used := false
		for e := 0; e < links; e += 1 {
			bit := input[4+links+s*links+e]
			if bit != 0 && bit != 1 do return -1
			path[s][e] = bit == 1
			if bit == 1 do used = true
		}
		if !used do return -1
	}
	output_bytes := 16*n
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for step := 0; step < updates; step += 1 {
		session := 0
		if mode == 0 { session = step%n }
		else if mode == 1 { for s := 1; s < n; s += 1 { if rate[s] < rate[session] { session = s } } }
		else if mode == 2 {
			found := false
			for s := 0; s < n && !found; s += 1 {
				local := true
				for j := 0; j < n && local; j += 1 { if j != s {
					shares := false
					for e := 0; e < links; e += 1 { if path[s][e] && path[j][e] { shares = true } }
					if shares && (rate[j] < rate[s] || (rate[j] == rate[s] && j < s)) { local = false }
				} }
				if local { session = s; found = true }
			}
		} else {
			selected := links
			best_load: i64 = 0
			for e := 0; e < links; e += 1 {
				load: i64 = 0; used := false
				for s := 0; s < n; s += 1 { if path[s][e] { load += rate[s]; used = true } }
				if used && (selected == links || load*cap[selected] > best_load*cap[e]) { selected = e; best_load = load }
			}
			for s := 0; s < n; s += 1 { if path[s][selected] { session = s; break } }
		}
		best: i64 = 0x7fffffffffffffff
		bottleneck := links
		for e := 0; e < links; e += 1 { if path[session][e] {
			fixed: i64 = 0; active := 1
			for j := 0; j < n; j += 1 { if j != session && path[j][e] { if rate[j] <= rate[session] { fixed += rate[j] } else { active += 1 } } }
			level := rate[session]
			candidate := level
			for pass := 0; pass < n; pass += 1 {
				numerator := cap[e]*SCALE-fixed
				if numerator < 0 || numerator%i64(active) != 0 do return -1
				candidate = numerator/i64(active)
				if candidate < level do return -1
				next: i64 = 0x7fffffffffffffff
				for j := 0; j < n; j += 1 { if j != session && path[j][e] && rate[j] > level && rate[j] < next { next = rate[j] } }
				if next == 0x7fffffffffffffff || candidate <= next do break
				saturated := 0
				for j := 0; j < n; j += 1 { if j != session && path[j][e] && rate[j] == next { saturated += 1 } }
				fixed += i64(saturated)*next; active -= saturated; level = next
			}
			if candidate < best { best = candidate; bottleneck = e }
		} }
		if bottleneck == links do return -1
		rate[session] = best
		for j := 0; j < n; j += 1 { if j != session && path[j][bottleneck] && rate[j] > best { rate[j] = best } }
	}
	staged: [MAX_OUTPUT]u8
	for s := 0; s < n; s += 1 { divisor := gcd64(rate[s], SCALE); put64(&staged[0],16*s,rate[s]/divisor); put64(&staged[0],16*s+8,SCALE/divisor) }
	for b := 0; b < output_bytes; b += 1 { output[b] = staged[b] }
	return i64(output_bytes)
}
