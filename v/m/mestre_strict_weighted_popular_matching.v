// Clean-room bounded implementation of Mestre's strict weighted profile.
module mestre_strict_weighted_popular_matching

const max_a = 4
const max_j = 5
const max_n = 9
const max_parseable = 31
const inf_label = i64(1_000_000_000)

fn ms_lambda_min(a int, target int, row []int, row_length []int,
	f_category []int, label []i64) i64 {
	mut best := inf_label
	for i in 0 .. row_length[a] {
		job := row[a * max_n + i]
		if job == target { break }
		if f_category[job] >= 0 && label[job] < best { best = label[job] }
	}
	return best
}

fn ms_augment(a int, edges []int, edge_count []int, mut owner []int, mut seen []bool) bool {
	for i in 0 .. edge_count[a] {
		job := edges[a * 2 + i]
		if seen[job] { continue }
		seen[job] = true
		previous := owner[job]
		if previous < 0 || ms_augment(previous, edges, edge_count, mut owner, mut seen) {
			owner[job] = a
			return true
		}
	}
	return false
}

fn ms_solve(applicants int, jobs int, weights []i64, lengths []int, listed []int) i64 {
	mut row := []int{len: max_a * max_n}
	mut row_length := []int{len: max_a}
	for a in 0 .. applicants {
		for i in 0 .. lengths[a] {
			row[a * max_n + row_length[a]] = listed[a * max_j + i]
			row_length[a]++
		}
		row[a * max_n + row_length[a]] = jobs + a
		row_length[a]++
	}
	mut category_weights := []i64{len: max_a}
	mut category_count := 0
	for a in 0 .. applicants {
		mut found := false
		for c in 0 .. category_count { if category_weights[c] == weights[a] { found = true } }
		if !found { category_weights[category_count] = weights[a]; category_count++ }
	}
	for i in 0 .. category_count { for j in i + 1 .. category_count {
		if category_weights[j] > category_weights[i] {
			category_weights[i], category_weights[j] = category_weights[j], category_weights[i]
		}
	} }
	mut category := []int{len: max_a}
	for a in 0 .. applicants { for category[a] < category_count && category_weights[category[a]] != weights[a] { category[a]++ } }
	mut first := []int{len: max_a}
	mut second := []int{len: max_a, init: -1}
	mut f_category := []int{len: max_n, init: -1}
	mut higher := []bool{len: max_n}
	mut label := []i64{len: max_n, init: inf_label}
	for c in 0 .. category_count {
		for a in 0 .. applicants { if category[a] == c {
			for i in 0 .. row_length[a] {
				p := row[a * max_n + i]
				if !higher[p] { first[a] = p; break }
			}
		} }
		for a in 0 .. applicants { if category[a] == c { f_category[first[a]] = c; higher[first[a]] = true } }
	}
	for a in 0 .. applicants { for i in 0 .. row_length[a] {
		p := row[a * max_n + i]
		if f_category[p] < 0 || f_category[p] > category[a] { second[a] = p; break }
	} }
	mut keep_first := []bool{len: max_a, init: true}
	mut keep_second := []bool{len: max_a}
	for a in 0 .. applicants { keep_second[a] = second[a] >= 0 }
	for c in 0 .. category_count {
		weight := category_weights[c]
		if c == 0 { for a in 0 .. applicants { if category[a] == c { label[first[a]] = weight } }; continue }
		for a in 0 .. applicants { if category[a] == c && ms_lambda_min(a, first[a], row, row_length, f_category, label) < weight { return 0 } }
		for p in 0 .. max_n { if f_category[p] == c {
			mut group := []int{cap: max_a}
			for a in 0 .. applicants { if category[a] == c && first[a] == p { group << a } }
			if group.len == 1 {
				earlier := ms_lambda_min(group[0], p, row, row_length, f_category, label)
				label[p] = if earlier >= inf_label { weight } else { min(weight, earlier - weight) }
			} else {
				label[p] = weight
				for a in group { if ms_lambda_min(a, p, row, row_length, f_category, label) < 2 * weight { keep_first[a] = false } }
			}
		} }
		for a in 0 .. applicants { if category[a] == c && second[a] >= 0 && ms_lambda_min(a, second[a], row, row_length, f_category, label) < weight { keep_second[a] = false } }
	}
	mut is_first := []bool{len: max_n}
	for a in 0 .. applicants { is_first[first[a]] = true }
	for p in 0 .. max_n {
		if is_first[p] {
			mut eligible := false
			for a in 0 .. applicants { if first[a] == p && keep_first[a] { eligible = true } }
			if !eligible { return 0 }
		}
	}
	mut edges := []int{len: max_a * 2}
	mut edge_count := []int{len: max_a}
	for a in 0 .. applicants {
		if keep_first[a] { edges[a * 2 + edge_count[a]] = first[a]; edge_count[a]++ }
		if keep_second[a] && second[a] >= 0 && !is_first[second[a]] { edges[a * 2 + edge_count[a]] = second[a]; edge_count[a]++ }
		if edge_count[a] == 0 { return 0 }
	}
	mut owner := []int{len: max_n, init: -1}
	for a in 0 .. applicants {
		mut seen := []bool{len: max_n}
		if !ms_augment(a, edges, edge_count, mut owner, mut seen) { return 0 }
	}
	return 1
}

@[export: 'mestre_strict_weighted_popular_matching']
pub fn mestre_strict_weighted_popular_matching(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable { return -1 }
		a64, j64 := input[0], input[1]
		if a64 < 1 || a64 > max_a || j64 < 1 || j64 > max_j { return -1 }
		applicants, jobs := int(a64), int(j64)
		if length < usize(2 + 2 * applicants) { return -1 }
		mut weights := []i64{len: max_a}
		mut lengths := []int{len: max_a}
		mut total := 0
		for a in 0 .. applicants {
			weights[a] = input[2 + a]
			size := input[2 + applicants + a]
			if weights[a] < 1 || weights[a] > 1000 || size < 1 || size > j64 { return -1 }
			lengths[a] = int(size); total += int(size)
		}
		if length != usize(2 + 2 * applicants + total) { return -1 }
		mut listed := []int{len: max_a * max_j}
		mut cursor := 2 + 2 * applicants
		for a in 0 .. applicants { for i in 0 .. lengths[a] {
			value := input[cursor]; cursor++
			if value < 0 || value >= j64 { return -1 }
			p := int(value)
			for k in 0 .. i { if listed[a * max_j + k] == p { return -1 } }
			listed[a * max_j + i] = p
		} }
		return ms_solve(applicants, jobs, weights, lengths, listed)
	}
}
