// Bounded clean-room strict-list maximum-cardinality popular matching.
package maximum_cardinality_popular_matching

import "core:c"

A :: 6
P :: 6
PARSEABLE :: 45

mp_augment :: proc "contextless" (applicant, posts: int, first, second: [A]int,
        owner: ^[P]int, assignment: ^[A]int, seen: ^[P]bool) -> bool {
	edge0, edge1 := first[applicant], -1
	count := 1
	if second[applicant] < posts { edge1 = second[applicant]; count = 2 }
	if count == 2 && edge1 < edge0 { edge0, edge1 = edge1, edge0 }
	for i := 0; i < count; i += 1 {
		post := edge0
		if i == 1 do post = edge1
		if seen[post] do continue
		seen[post] = true
		previous := owner[post]
		if previous < 0 || mp_augment(previous, posts, first, second, owner, assignment, seen) {
			owner[post] = applicant
			assignment[applicant] = post
			return true
		}
	}
	return false
}

mp_solve :: proc "contextless" (applicants, posts: int, preferences: [36]int,
		lengths: [A]int) -> i64 {
	first, second: [A]int
	first_post: [P]bool
	for a := 0; a < applicants; a += 1 {
		first[a] = preferences[a * P]
		first_post[first[a]] = true
	}
	for a := 0; a < applicants; a += 1 {
		second[a] = posts + a
		for j := 0; j < lengths[a]; j += 1 {
			candidate := preferences[a * P + j]
			if !first_post[candidate] { second[a] = candidate; break }
		}
	}
	active_a: [A]bool
	active_p: [P]bool
	assignment: [A]int
	for a := 0; a < applicants; a += 1 {
		active_a[a] = second[a] < posts
		assignment[a] = -1
	}
	for p := 0; p < posts; p += 1 { active_p[p] = true }
	for {
		degree, sole: [P]int
		for p := 0; p < P; p += 1 { sole[p] = -1 }
		for a := 0; a < applicants; a += 1 {
			if active_a[a] {
				for k := 0; k < 2; k += 1 {
					post := first[a]
					if k == 1 do post = second[a]
					if active_p[post] { degree[post] += 1; sole[post] = a }
				}
			}
		}
		forced := -1
		for p := 0; p < posts; p += 1 {
			if active_p[p] && degree[p] == 1 { forced = p; break }
		}
		if forced < 0 do break
		a := sole[forced]
		assignment[a] = forced
		active_a[a] = false
		active_p[forced] = false
	}

	degree: [P]int
	neighbors: [P][2]int
	neighbor_count: [P]int
	active_count, residual_posts := 0, 0
	for a := 0; a < applicants; a += 1 {
		if active_a[a] {
			active_count += 1
			for k := 0; k < 2; k += 1 {
				post := first[a]
				if k == 1 do post = second[a]
				if !active_p[post] do return 0
				if neighbor_count[post] < 2 { neighbors[post][neighbor_count[post]] = a }
				neighbor_count[post] += 1
				degree[post] += 1
			}
		}
	}
	for post := 0; post < posts; post += 1 {
		if active_p[post] && degree[post] > 0 {
			residual_posts += 1
			if degree[post] != 2 || neighbor_count[post] != 2 do return 0
		}
	}
	if residual_posts < active_count || residual_posts != active_count do return 0

	visited: [A]bool
	for root := 0; root < applicants; root += 1 {
		if active_a[root] && !visited[root] {
			current_post := first[root]
			if second[root] < current_post do current_post = second[root]
			assignment[root] = current_post
			visited[root] = true
			current_a := root
			for {
				next_a := neighbors[current_post][0]
				if next_a == current_a do next_a = neighbors[current_post][1]
				if next_a == root do break
				if visited[next_a] do return 0
				next_post := first[next_a]
				if first[next_a] == current_post do next_post = second[next_a]
				assignment[next_a] = next_post
				visited[next_a] = true
				current_a, current_post = next_a, next_post
			}
		}
	}

	owner: [P]int
	for p := 0; p < P; p += 1 { owner[p] = -1 }
	for a := 0; a < applicants; a += 1 { if assignment[a] >= 0 do owner[assignment[a]] = a }
	for a := 0; a < applicants; a += 1 {
		if second[a] >= posts && assignment[a] < 0 {
			seen: [P]bool
			_ = mp_augment(a, posts, first, second, &owner, &assignment, &seen)
		}
	}
	for a := 0; a < applicants; a += 1 { if assignment[a] < 0 do assignment[a] = posts + a }
	for post := 0; post < posts; post += 1 {
		if first_post[post] && owner[post] < 0 {
			a := 0
			for first[a] != post { a += 1 }
			old := assignment[a]
			if old < posts do owner[old] = -1
			assignment[a] = post
			owner[post] = a
		}
	}
	result := 0
	for a := 0; a < applicants; a += 1 { if assignment[a] < posts do result += 1 }
	return i64(result)
}

@(export)
maximum_cardinality_popular_matching :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(PARSEABLE) do return -1
	a_value, p_value := input[0], input[1]
	if a_value < 1 || a_value > A || p_value < 1 || p_value > P do return -1
	applicants, posts := int(a_value), int(p_value)
	if length < c.size_t(2 + applicants) do return -1
	lengths: [A]int
	total := 0
	for a := 0; a < applicants; a += 1 {
		size := input[2 + a]
		if size < 1 || size > p_value do return -1
		lengths[a] = int(size)
		total += int(size)
	}
	if length != c.size_t(2 + applicants + total) do return -1
	preferences: [36]int
	cursor := 2 + applicants
	for a := 0; a < applicants; a += 1 {
		for j := 0; j < lengths[a]; j += 1 {
			value := input[cursor]
			cursor += 1
			if value < 0 || value >= p_value do return -1
			post := int(value)
			for k := 0; k < j; k += 1 { if preferences[a * P + k] == post do return -1 }
			preferences[a * P + j] = post
		}
	}
	return mp_solve(applicants, posts, preferences, lengths)
}
