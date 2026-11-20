// Bounded clean-room strict-list maximum-cardinality popular matching.
const max_a = 6
const max_p = 6
const max_parseable = 45

fn mp_augment(applicant int, posts int, first []int, second []int,
	mut owner []int, mut assignment []int, mut seen []bool) bool {
	mut edges := []int{cap: 2}
	edges << first[applicant]
	if second[applicant] < posts { edges << second[applicant] }
	if edges.len == 2 && edges[1] < edges[0] { edges[0], edges[1] = edges[1], edges[0] }
	for post in edges {
		if seen[post] { continue }
		seen[post] = true
		previous := owner[post]
		if previous < 0 || mp_augment(previous, posts, first, second, mut owner, mut assignment, mut seen) {
			owner[post] = applicant
			assignment[applicant] = post
			return true
		}
	}
	return false
}

fn mp_solve(applicants int, posts int, preferences []int, lengths []int) i64 {
	mut first := []int{len: max_a}
	mut second := []int{len: max_a}
	mut first_post := []bool{len: max_p}
	for a in 0 .. applicants {
		first[a] = preferences[a * max_p]
		first_post[first[a]] = true
	}
	for a in 0 .. applicants {
		second[a] = posts + a
		for j in 0 .. lengths[a] {
			candidate := preferences[a * max_p + j]
			if !first_post[candidate] { second[a] = candidate; break }
		}
	}
	mut active_a := []bool{len: max_a}
	mut active_p := []bool{len: max_p}
	mut assignment := []int{len: max_a, init: -1}
	for a in 0 .. applicants { active_a[a] = second[a] < posts }
	for p in 0 .. posts { active_p[p] = true }
	for {
		mut degree := []int{len: max_p}
		mut sole := []int{len: max_p, init: -1}
		for a in 0 .. applicants {
			if active_a[a] {
				for k in 0 .. 2 {
					post := if k == 0 { first[a] } else { second[a] }
					if active_p[post] { degree[post]++; sole[post] = a }
				}
			}
		}
		mut forced := -1
		for p in 0 .. posts {
			if active_p[p] && degree[p] == 1 { forced = p; break }
		}
		if forced < 0 { break }
		a := sole[forced]
		assignment[a] = forced
		active_a[a] = false
		active_p[forced] = false
	}

	mut degree := []int{len: max_p}
	mut neighbor0 := []int{len: max_p, init: -1}
	mut neighbor1 := []int{len: max_p, init: -1}
	mut neighbor_count := []int{len: max_p}
	mut active_count := 0
	for a in 0 .. applicants {
		if active_a[a] {
			active_count++
			for k in 0 .. 2 {
				post := if k == 0 { first[a] } else { second[a] }
				if !active_p[post] { return 0 }
				if neighbor_count[post] == 0 { neighbor0[post] = a }
				else if neighbor_count[post] == 1 { neighbor1[post] = a }
				neighbor_count[post]++
				degree[post]++
			}
		}
	}
	mut residual_posts := 0
	for p in 0 .. posts {
		if active_p[p] && degree[p] > 0 {
			residual_posts++
			if degree[p] != 2 || neighbor_count[p] != 2 { return 0 }
		}
	}
	if residual_posts < active_count || residual_posts != active_count { return 0 }

	mut visited := []bool{len: max_a}
	for root in 0 .. applicants {
		if active_a[root] && !visited[root] {
			mut current_post := if first[root] < second[root] { first[root] } else { second[root] }
			assignment[root] = current_post
			visited[root] = true
			mut current_a := root
			for {
				next_a := if neighbor0[current_post] != current_a { neighbor0[current_post] } else { neighbor1[current_post] }
				if next_a == root { break }
				if visited[next_a] { return 0 }
				next_post := if first[next_a] == current_post { second[next_a] } else { first[next_a] }
				assignment[next_a] = next_post
				visited[next_a] = true
				current_a = next_a
				current_post = next_post
			}
		}
	}

	mut owner := []int{len: max_p, init: -1}
	for a in 0 .. applicants { if assignment[a] >= 0 { owner[assignment[a]] = a } }
	for a in 0 .. applicants {
		if second[a] >= posts && assignment[a] < 0 {
			mut seen := []bool{len: max_p}
			_ = mp_augment(a, posts, first, second, mut owner, mut assignment, mut seen)
		}
	}
	for a in 0 .. applicants { if assignment[a] < 0 { assignment[a] = posts + a } }
	for p in 0 .. posts {
		if first_post[p] && owner[p] < 0 {
			mut a := 0
			for first[a] != p { a++ }
			old := assignment[a]
			if old < posts { owner[old] = -1 }
			assignment[a] = p
			owner[p] = a
		}
	}
	mut result := 0
	for a in 0 .. applicants { if assignment[a] < posts { result++ } }
	return i64(result)
}

@[export: 'maximum_cardinality_popular_matching']
pub fn maximum_cardinality_popular_matching(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable { return -1 }
		a64, p64 := input[0], input[1]
		if a64 < 1 || a64 > max_a || p64 < 1 || p64 > max_p { return -1 }
		applicants, posts := int(a64), int(p64)
		if length < usize(2 + applicants) { return -1 }
		mut lengths := []int{len: max_a}
		mut total := 0
		for a in 0 .. applicants {
			size := input[2 + a]
			if size < 1 || size > p64 { return -1 }
			lengths[a] = int(size)
			total += int(size)
		}
		if length != usize(2 + applicants + total) { return -1 }
		mut preferences := []int{len: max_a * max_p}
		mut cursor := 2 + applicants
		for a in 0 .. applicants {
			for j in 0 .. lengths[a] {
				value := input[cursor]
				cursor++
				if value < 0 || value >= p64 { return -1 }
				post := int(value)
				for k in 0 .. j { if preferences[a * max_p + k] == post { return -1 } }
				preferences[a * max_p + j] = post
			}
		}
		return mp_solve(applicants, posts, preferences, lengths)
	}
}
