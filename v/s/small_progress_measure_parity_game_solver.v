module small_progress_measure_parity_game_solver

type Rank = [3]u8

struct ProgressValue {
	rank Rank
	top bool
}

fn spm_compare(left Rank, left_top bool, right Rank, right_top bool) int {
	if left_top != right_top { return if left_top { 1 } else { -1 } }
	if left_top { return 0 }
	for index in 0 .. 3 {
		if left[index] < right[index] { return -1 }
		if left[index] > right[index] { return 1 }
	}
	return 0
}

fn spm_progress(target Rank, target_top bool, priority u8, bounds Rank) ProgressValue {
	mut result := target
	if target_top { return ProgressValue{result, true} }
	included := if priority < 1 { 0 } else if priority < 3 { 1 } else if priority < 5 { 2 } else { 3 }
	for index in included .. 3 { result[index] = 0 }
	if priority % 2 == 0 { return ProgressValue{result, false} }
	mut cursor := included
	for cursor > 0 {
		cursor--
		if result[cursor] < bounds[cursor] {
			result[cursor]++
			for suffix in cursor + 1 .. included { result[suffix] = 0 }
			return ProgressValue{result, false}
		}
		result[cursor] = 0
	}
	return ProgressValue{Rank{0, 0, 0}, true}
}

@[export: 'small_progress_measure_parity_game_solver']
pub fn small_progress_measure_parity_game_solver(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > 59 { return -1 }
		n_raw, m_raw := input[0], input[1]
		if n_raw < 1 || n_raw > 8 || m_raw < n_raw || m_raw > 20 { return -1 }
		n, m := int(n_raw), int(m_raw)
		if length != usize(2 + 2 * n + 2 * m) { return -1 }
		mut owners := [8]u8{}
		mut priorities := [8]u8{}
		mut adjacency := [8]u16{}
		mut outdegree := [8]int{}
		mut bounds := Rank{}
		mut measures := [8]Rank{}
		mut tops := [8]bool{}
		mut cursor := 2
		for vertex in 0 .. n {
			owner, priority := input[cursor], input[cursor + 1]
			cursor += 2
			if owner < 0 || owner > 1 || priority < 0 || priority > 5 { return -1 }
			owners[vertex], priorities[vertex] = u8(owner), u8(priority)
			if priority == 1 { bounds[0]++ }
			if priority == 3 { bounds[1]++ }
			if priority == 5 { bounds[2]++ }
		}
		for _ in 0 .. m {
			source_raw, destination_raw := input[cursor], input[cursor + 1]
			cursor += 2
			if source_raw < 0 || source_raw >= n_raw || destination_raw < 0 || destination_raw >= n_raw { return -1 }
			source, destination := int(source_raw), int(destination_raw)
			bit := u16(1) << destination
			if adjacency[source] & bit != 0 { return -1 }
			adjacency[source] |= bit
			outdegree[source]++
		}
		for vertex in 0 .. n { if outdegree[vertex] == 0 { return -1 } }
		for {
			mut changed := false
			for vertex in 0 .. n {
				mut best := Rank{}
				mut best_top := owners[vertex] == 1
				mut has_best := false
				for destination in 0 .. n {
					if adjacency[vertex] & (u16(1) << destination) == 0 { continue }
					candidate := spm_progress(measures[destination], tops[destination], priorities[vertex], bounds)
					order := spm_compare(candidate.rank, candidate.top, best, best_top)
					if !has_best || (owners[vertex] == 0 && order < 0) || (owners[vertex] == 1 && order > 0) {
						best, best_top, has_best = candidate.rank, candidate.top, true
					}
				}
				if spm_compare(measures[vertex], tops[vertex], best, best_top) < 0 {
					measures[vertex], tops[vertex] = best, best_top
					changed = true
				}
			}
			if !changed { break }
		}
		mut winners := i64(0)
		for vertex in 0 .. n { if !tops[vertex] { winners |= i64(1) << vertex } }
		return winners
	}
}
