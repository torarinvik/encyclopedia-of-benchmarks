package small_progress_measure_parity_game_solver

import "core:c"

Rank :: [3]u8

spm_compare :: proc(left: Rank, left_top: bool, right: Rank, right_top: bool) -> int {
	if left_top != right_top {
		if left_top do return 1
		return -1
	}
	if left_top do return 0
	for index := 0; index < 3; index += 1 {
		if left[index] < right[index] do return -1
		if left[index] > right[index] do return 1
	}
	return 0
}

spm_progress :: proc(target: Rank, target_top: bool, priority: u8, bounds: Rank) -> (Rank, bool) {
	result := target
	if target_top do return result, true
	included := 0
	if priority >= 1 do included = 1
	if priority >= 3 do included = 2
	if priority >= 5 do included = 3
	for index := included; index < 3; index += 1 do result[index] = 0
	if priority % 2 == 0 do return result, false
	for cursor := included; cursor > 0; {
		cursor -= 1
		if result[cursor] < bounds[cursor] {
			result[cursor] += 1
			for suffix := cursor + 1; suffix < included; suffix += 1 do result[suffix] = 0
			return result, false
		}
		result[cursor] = 0
	}
	return Rank{0, 0, 0}, true
}

@(export)
small_progress_measure_parity_game_solver :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > 59 do return -1
	n_raw, m_raw := input[0], input[1]
	if n_raw < 1 || n_raw > 8 || m_raw < n_raw || m_raw > 20 do return -1
	n, m := int(n_raw), int(m_raw)
	if length != c.size_t(2 + 2*n + 2*m) do return -1
	owners: [8]u8
	priorities: [8]u8
	adjacency: [8]u16
	outdegree: [8]int
	bounds: Rank
	measures: [8]Rank
	tops: [8]bool
	cursor := c.size_t(2)
	for vertex := 0; vertex < n; vertex += 1 {
		owner, priority := input[cursor], input[cursor+1]
		cursor += 2
		if owner < 0 || owner > 1 || priority < 0 || priority > 5 do return -1
		owners[vertex], priorities[vertex] = u8(owner), u8(priority)
		if priority == 1 do bounds[0] += 1
		if priority == 3 do bounds[1] += 1
		if priority == 5 do bounds[2] += 1
	}
	for _ := 0; _ < m; _ += 1 {
		source_raw, destination_raw := input[cursor], input[cursor+1]
		cursor += 2
		if source_raw < 0 || source_raw >= n_raw || destination_raw < 0 || destination_raw >= n_raw do return -1
		source, destination := int(source_raw), int(destination_raw)
		bit := u16(1) << destination
		if adjacency[source]&bit != 0 do return -1
		adjacency[source] |= bit
		outdegree[source] += 1
	}
	for vertex := 0; vertex < n; vertex += 1 do if outdegree[vertex] == 0 do return -1
	for {
		changed := false
		for vertex := 0; vertex < n; vertex += 1 {
			best: Rank
			best_top := owners[vertex] == 1
			has_best := false
			for destination := 0; destination < n; destination += 1 {
				if adjacency[vertex]&(u16(1)<<destination) == 0 do continue
				candidate, candidate_top := spm_progress(measures[destination], tops[destination], priorities[vertex], bounds)
				order := spm_compare(candidate, candidate_top, best, best_top)
				if !has_best || (owners[vertex] == 0 && order < 0) || (owners[vertex] == 1 && order > 0) {
					best, best_top, has_best = candidate, candidate_top, true
				}
			}
			if spm_compare(measures[vertex], tops[vertex], best, best_top) < 0 {
				measures[vertex], tops[vertex] = best, best_top
				changed = true
			}
		}
		if !changed do break
	}
	winners: i64 = 0
	for vertex := 0; vertex < n; vertex += 1 do if !tops[vertex] do winners |= i64(1) << vertex
	return winners
}
