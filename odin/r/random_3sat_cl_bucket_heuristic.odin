package random_3sat_cl_bucket_heuristic

import "core:c"

MAX_N :: 8
MAX_M :: 24
MAX_PARSEABLE_INPUT :: 99
MAX_WORDS :: 44

Formula :: struct {
	clauses: [MAX_M][3]int,
	lens: [MAX_M]int,
	active: [MAX_M]bool,
}
Event :: struct { literal, kind, bi, bj: i64 }

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { out[at+b] = u8(bits & 255); bits >>= 8 }
}

reduce :: proc(f: ^Formula, m: int, assigned: ^[MAX_N]int, literal: int) -> bool {
	v := (if literal > 0 do literal else -literal) - 1
	value := (if literal > 0 do 1 else -1)
	if assigned[v] != 0 && assigned[v] != value do return false
	assigned[v] = value
	for c := 0; c < m; c += 1 {
		if !f.active[c] do continue
		satisfied := false
		for j := 0; j < f.lens[c]; j += 1 { if f.clauses[c][j] == literal do satisfied = true }
		if satisfied { f.active[c] = false; continue }
		kept := 0
		for j := 0; j < f.lens[c]; j += 1 {
			if f.clauses[c][j] != -literal { f.clauses[c][kept] = f.clauses[c][j]; kept += 1 }
		}
		f.lens[c] = kept
		if kept == 0 do return false
	}
	return true
}

propagate :: proc(f: ^Formula, m: int, assigned: ^[MAX_N]int, events: ^[MAX_N]Event,
	count: ^int, record: bool) -> bool {
	for {
		unit := 0
		for c := 0; c < m; c += 1 { if unit == 0 && f.active[c] && f.lens[c] == 1 do unit = f.clauses[c][0] }
		if unit == 0 do return true
		if record { events[count^] = Event{literal = i64(unit), kind = 1, bi = -1, bj = -1}; count^ += 1 }
		if !reduce(f, m, assigned, unit) do return false
	}
}

degrees :: proc(f: Formula, m, n: int) -> ([MAX_N]int, [MAX_N]int) {
	positive: [MAX_N]int
	negative: [MAX_N]int
	for c := 0; c < m; c += 1 { if f.active[c] {
		for j := 0; j < f.lens[c]; j += 1 {
			literal := f.clauses[c][j]
			v := (if literal > 0 do literal else -literal) - 1
			if literal > 0 { positive[v] += 1 } else { negative[v] += 1 }
		}
	} }
	_ = n
	return positive, negative
}

member :: proc(f: Formula, m, n: int, assigned: [MAX_N]int, bi, bj: int) -> int {
	positive, negative := degrees(f, m, n)
	for v := 0; v < n; v += 1 {
		if assigned[v] != 0 do continue
		p := min(10, positive[v]); q := min(10, negative[v])
		if p == bi && q == bj do return v + 1
		if q == bi && p == bj do return -(v + 1)
	}
	return 0
}

flows :: proc(f: Formula, m, n: int) -> (i64, i64, i64) {
	p2: [MAX_N]i64; n2: [MAX_N]i64; p3: [MAX_N]i64; n3: [MAX_N]i64
	clauses2: i64 = 0
	for c := 0; c < m; c += 1 { if f.active[c] {
		if f.lens[c] == 2 { clauses2 += 1; for j := 0; j < 2; j += 1 { x := f.clauses[c][j]; v := (if x > 0 do x else -x)-1; if x > 0 { p2[v] += 1 } else { n2[v] += 1 } } }
		else if f.lens[c] == 3 { for j := 0; j < 3; j += 1 { x := f.clauses[c][j]; v := (if x > 0 do x else -x)-1; if x > 0 { p3[v] += 1 } else { n3[v] += 1 } } }
	} }
	s2: i64 = 0; s3: i64 = 0
	for c := 0; c < m; c += 1 { if f.active[c] && f.lens[c] == 2 {
		for j := 0; j < 2; j += 1 { x := -f.clauses[c][j]; v := (if x > 0 do x else -x)-1; if x > 0 { s2 += p2[v]; s3 += p3[v] } else { s2 += n2[v]; s3 += n3[v] } }
	} }
	_ = n
	den := (if clauses2 == 0 do i64(1) else 2*clauses2)
	return s2, s3, den
}

choose_bucket :: proc(f: Formula, m, n: int, assigned: [MAX_N]int) -> (bool, int, int) {
	old2, old3, oldden := flows(f, m, n)
	found := false; best_num: i64 = 0; best_den: i64 = 1; best_i := -1; best_j := -1
	for bi := 0; bi <= 10; bi += 1 { for bj := 0; bj <= 10; bj += 1 {
		literal := member(f, m, n, assigned, bi, bj)
		if literal == 0 do continue
		trial := f; trial_assigned := assigned; ignored: [MAX_N]Event; ignored_count := 0
		if !reduce(&trial, m, &trial_assigned, literal) do continue
		if !propagate(&trial, m, &trial_assigned, &ignored, &ignored_count, false) do continue
		next2, next3, nextden := flows(trial, m, n)
		numerator := next2*oldden-old2*nextden; denominator := next3*oldden-old3*nextden
		if denominator == 0 do continue
		if denominator < 0 { numerator = -numerator; denominator = -denominator }
		if !found || numerator*best_den > best_num*denominator ||
			(numerator*best_den == best_num*denominator && (bi < best_i || (bi == best_i && bj < best_j))) {
			found = true; best_num = numerator; best_den = denominator; best_i = bi; best_j = bj
		}
	} }
	return found, best_i, best_j
}

@(export)
random_3sat_cl_bucket_heuristic :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M do return -1
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2+4*m) do return -1
	f: Formula
	for cidx := 0; cidx < m; cidx += 1 {
		base := 2+4*cidx; rawk := input[base]
		if rawk < 1 || rawk > 3 do return -1
		k := int(rawk); seen: [MAX_N]bool
		for j := 0; j < 3; j += 1 {
			raw := input[base+1+j]
			if j < k { if raw == 0 || raw < -i64(n) || raw > i64(n) do return -1
				v := int(abs(raw))-1; if seen[v] do return -1; seen[v] = true; f.clauses[cidx][j] = int(raw)
			} else if raw != 0 { return -1 }
		}
		f.lens[cidx] = k; f.active[cidx] = true
	}
	assigned: [MAX_N]int; events: [MAX_N]Event; count := 0; status: i64 = 0
	if !propagate(&f, m, &assigned, &events, &count, true) do status = 1
	for status == 0 {
		pending := false; for v := 0; v < n; v += 1 { if assigned[v] == 0 do pending = true }
		if !pending do break
		found, bi, bj := choose_bucket(f, m, n, assigned)
		if !found do { status = 2; break }
		literal := member(f, m, n, assigned, bi, bj)
		if literal == 0 do { status = 2; break }
		events[count] = Event{literal = i64(literal), kind = 0, bi = i64(bi), bj = i64(bj)}; count += 1
		if !reduce(&f, m, &assigned, literal) do { status = 1; break }
		if !propagate(&f, m, &assigned, &events, &count, true) do { status = 1; break }
	}
	words: [MAX_WORDS]i64; at := 0; words[at] = status; at += 1; words[at] = i64(n); at += 1
	assigned_count := 0; for v := 0; v < n; v += 1 { if assigned[v] != 0 do assigned_count += 1 }
	words[at] = i64(assigned_count); at += 1; for v := 0; v < n; v += 1 { words[at] = i64(assigned[v]); at += 1 }
	words[at] = i64(count); at += 1; for i := 0; i < count; i += 1 { words[at] = events[i].literal; at += 1; words[at] = events[i].kind; at += 1; words[at] = events[i].bi; at += 1; words[at] = events[i].bj; at += 1 }
	bytes := at*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	staged: [352]u8
	for i := 0; i < at; i += 1 { put_i64(&staged[0], 8*i, words[i]) }
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
