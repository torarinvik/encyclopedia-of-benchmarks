module random_3sat_cl_bucket_heuristic

const max_vars = 8
const max_clauses = 24
const max_parseable_input = 99
const max_words = 44

struct Formula {
mut:
	clauses [max_clauses][3]int
	lens [max_clauses]int
	active [max_clauses]bool
}

struct Event {
	literal i64
	kind i64
	bi i64
	bj i64
}

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

fn simplify(mut f Formula, m int, mut assigned [max_vars]int, literal int) bool {
	variable := (if literal > 0 { literal } else { -literal }) - 1
	value := if literal > 0 { 1 } else { -1 }
	if assigned[variable] != 0 && assigned[variable] != value { return false }
	assigned[variable] = value
	for c in 0 .. m {
		if !f.active[c] { continue }
		mut satisfied := false
		for j in 0 .. f.lens[c] { if f.clauses[c][j] == literal { satisfied = true } }
		if satisfied { f.active[c] = false; continue }
		mut kept := 0
		for j in 0 .. f.lens[c] {
			if f.clauses[c][j] != -literal { f.clauses[c][kept] = f.clauses[c][j]; kept++ }
		}
		f.lens[c] = kept
		if kept == 0 { return false }
	}
	return true
}

fn propagate(mut f Formula, m int, mut assigned [max_vars]int, mut events [max_vars]Event,
	mut count int, record bool) bool {
	for {
		mut unit := 0
		for c in 0 .. m { if unit == 0 && f.active[c] && f.lens[c] == 1 { unit = f.clauses[c][0] } }
		if unit == 0 { return true }
		if record { events[count] = Event{literal: i64(unit), kind: 1, bi: -1, bj: -1}; count++ }
		if !simplify(mut f, m, mut assigned, unit) { return false }
	}
}

fn degrees(f Formula, m int, n int) ([max_vars]int, [max_vars]int) {
	mut positive := [max_vars]int{}
	mut negative := [max_vars]int{}
	for c in 0 .. m { if f.active[c] {
		for j in 0 .. f.lens[c] {
			literal := f.clauses[c][j]
			variable := (if literal > 0 { literal } else { -literal }) - 1
			if literal > 0 { positive[variable]++ } else { negative[variable]++ }
		}
	} }
	_ = n
	return positive, negative
}

fn member(f Formula, m int, n int, assigned [max_vars]int, bi int, bj int) int {
	positive, negative := degrees(f, m, n)
	for v in 0 .. n {
		if assigned[v] != 0 { continue }
		p := if positive[v] < 10 { positive[v] } else { 10 }
		q := if negative[v] < 10 { negative[v] } else { 10 }
		if p == bi && q == bj { return v + 1 }
		if q == bi && p == bj { return -(v + 1) }
	}
	return 0
}

fn flows(f Formula, m int, n int) (i64, i64, i64) {
	mut p2 := [max_vars]i64{}
	mut n2 := [max_vars]i64{}
	mut p3 := [max_vars]i64{}
	mut n3 := [max_vars]i64{}
	mut clause2 := i64(0)
	for c in 0 .. m { if f.active[c] {
		if f.lens[c] == 2 {
			clause2++
			for j in 0 .. 2 { x := f.clauses[c][j]; v := (if x > 0 { x } else { -x }) - 1; if x > 0 { p2[v]++ } else { n2[v]++ } }
		} else if f.lens[c] == 3 {
			for j in 0 .. 3 { x := f.clauses[c][j]; v := (if x > 0 { x } else { -x }) - 1; if x > 0 { p3[v]++ } else { n3[v]++ } }
		}
	} }
	mut s2 := i64(0)
	mut s3 := i64(0)
	for c in 0 .. m { if f.active[c] && f.lens[c] == 2 {
		for j in 0 .. 2 {
			x := -f.clauses[c][j]
			v := (if x > 0 { x } else { -x }) - 1
			if x > 0 { s2 += p2[v]; s3 += p3[v] } else { s2 += n2[v]; s3 += n3[v] }
		}
	} }
	_ = n
	return s2, s3, if clause2 == 0 { i64(1) } else { 2 * clause2 }
}

fn choose_bucket(f Formula, m int, n int, assigned [max_vars]int) (bool, int, int) {
	old2, old3, oldden := flows(f, m, n)
	mut found := false
	mut best_num := i64(0)
	mut best_den := i64(1)
	mut best_i := -1
	mut best_j := -1
	for bi in 0 .. 11 { for bj in 0 .. 11 {
		literal := member(f, m, n, assigned, bi, bj)
		if literal == 0 { continue }
		mut trial := f
		mut trial_assigned := assigned
		mut ignored_events := [max_vars]Event{}
		mut ignored_count := 0
		if !simplify(mut trial, m, mut trial_assigned, literal) { continue }
		if !propagate(mut trial, m, mut trial_assigned, mut ignored_events, mut ignored_count, false) { continue }
		next2, next3, nextden := flows(trial, m, n)
		mut numerator := next2 * oldden - old2 * nextden
		mut denominator := next3 * oldden - old3 * nextden
		if denominator == 0 { continue }
		if denominator < 0 { numerator = -numerator; denominator = -denominator }
		if !found || numerator * best_den > best_num * denominator ||
			(numerator * best_den == best_num * denominator && (bi < best_i || (bi == best_i && bj < best_j))) {
			found = true; best_num = numerator; best_den = denominator; best_i = bi; best_j = bj
		}
	} }
	return found, best_i, best_j
}

@[export: 'random_3sat_cl_bucket_heuristic']
pub fn random_3sat_cl_bucket_heuristic(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_parseable_input { return -1 }
	n64 := unsafe { input[0] }
	m64 := unsafe { input[1] }
	if n64 < 1 || n64 > max_vars || m64 < 0 || m64 > max_clauses || length != usize(2 + 4 * m64) { return -1 }
	n := int(n64); m := int(m64)
	mut f := Formula{}
	for c in 0 .. m {
		base := 2 + 4 * c
		raw_k := unsafe { input[base] }
		if raw_k < 1 || raw_k > 3 { return -1 }
		k := int(raw_k)
		mut seen := [max_vars]bool{}
		f.lens[c] = k
		for j in 0 .. 3 {
			raw := unsafe { input[base + 1 + j] }
			if j < k {
				if raw == 0 || raw < -n64 || raw > n64 { return -1 }
				v := int(if raw > 0 { raw } else { -raw }) - 1
				if seen[v] { return -1 }
				seen[v] = true; f.clauses[c][j] = int(raw)
			} else if raw != 0 { return -1 }
		}
		f.active[c] = true
	}
	mut assigned := [max_vars]int{}
	mut events := [max_vars]Event{}
	mut count := 0
	mut status := 0
	if !propagate(mut f, m, mut assigned, mut events, mut count, true) { status = 1 }
	for status == 0 {
		mut pending := false
		for v in 0 .. n { if assigned[v] == 0 { pending = true } }
		if !pending { break }
		found, bi, bj := choose_bucket(f, m, n, assigned)
		if !found { status = 2; break }
		literal := member(f, m, n, assigned, bi, bj)
		if literal == 0 { status = 2; break }
		events[count] = Event{literal: i64(literal), kind: 0, bi: i64(bi), bj: i64(bj)}; count++
		if !simplify(mut f, m, mut assigned, literal) { status = 1; break }
		if !propagate(mut f, m, mut assigned, mut events, mut count, true) { status = 1; break }
	}
	mut words := [max_words]i64{}
	mut at := 0
	words[at] = status; at++
	words[at] = i64(n); at++
	mut assigned_count := 0
	for v in 0 .. n { if assigned[v] != 0 { assigned_count++ } }
	words[at] = i64(assigned_count); at++
	for v in 0 .. n { words[at] = i64(assigned[v]); at++ }
	words[at] = i64(count); at++
	for i in 0 .. count { words[at] = events[i].literal; at++; words[at] = events[i].kind; at++; words[at] = events[i].bi; at++; words[at] = events[i].bj; at++ }
	bytes := at * 8
	if output == nil || capacity < usize(bytes) { return -2 }
	mut staged := [352]u8{}
	for i in 0 .. at { put_i64(mut &staged[0], 8 * i, words[i]) }
	for i in 0 .. bytes { unsafe { output[i] = staged[i] } }
	return i64(bytes)
}
