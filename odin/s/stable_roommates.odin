package stable_roommates

import "core:c"

MAX_N :: 8
MAX_INPUT_LENGTH :: 58
PREFERENCE_STRIDE :: MAX_N + 1

has_stable_roommates :: proc(n: int, preferences: [MAX_N * PREFERENCE_STRIDE]int,
		 ranking: [MAX_N * MAX_N]int) -> bool {
	var leftmost: [MAX_N]int
	var rightmost: [MAX_N]int
	var proposed_to: [MAX_N]bool
	for person := 0; person < n; person += 1 {
		leftmost[person] = 0
		rightmost[person] = n - 1
	}

	proposer, next_choice := 0, 0
	for start := 0; start < n; start += 1 {
		proposer = start
		steps := 0
		for {
			if leftmost[proposer] > rightmost[proposer] || leftmost[proposer] >= n do return false
			next_choice = preferences[proposer * PREFERENCE_STRIDE + leftmost[proposer]]
			if next_choice == proposer do return false
			current := preferences[next_choice * PREFERENCE_STRIDE + rightmost[next_choice]]
			for ranking[next_choice * MAX_N + proposer] > ranking[next_choice * MAX_N + current] {
				leftmost[proposer] += 1
				if leftmost[proposer] > rightmost[proposer] || leftmost[proposer] >= n do return false
				next_choice = preferences[proposer * PREFERENCE_STRIDE + leftmost[proposer]]
				if next_choice == proposer do return false
				current = preferences[next_choice * PREFERENCE_STRIDE + rightmost[next_choice]]
			}
			rightmost[next_choice] = ranking[next_choice * MAX_N + proposer]
			proposer = current
			if !proposed_to[next_choice] {
				proposed_to[next_choice] = true
				break
			}
			steps += 1
			if steps > n * n do return false
		}
	}
	if proposer != next_choice do return false
	for person := 0; person < n; person += 1 {
		if leftmost[person] > rightmost[person] do return false
	}

	var second: [MAX_N]int
	for person := 0; person < n; person += 1 { second[person] = leftmost[person] + 1 }
	var first_unmatched := 0
	var first_in_cycle := 0
	var tail: [MAX_N]bool
	var cycle: [MAX_N + 1]int
	for {
		for first_unmatched < n && leftmost[first_unmatched] == rightmost[first_unmatched] {
			first_unmatched += 1
		}
		if first_unmatched >= n {
			for person := 0; person < n; person += 1 {
				partner := preferences[person * PREFERENCE_STRIDE + leftmost[person]]
				if partner == person || preferences[partner * PREFERENCE_STRIDE + leftmost[partner]] != person do return false
			}
			return true
		}

		var visited: [MAX_N]bool
		person, position := 0, 0
		if first_in_cycle > 0 {
			visited = tail
			person = cycle[first_in_cycle - 1]
			position = first_in_cycle - 1
		} else {
			person = first_unmatched
		}

		repeated_person := -1
		for {
			if position >= MAX_N + 1 do return false
			cycle[position] = person
			position += 1
			visited[person] = true

			list_position := second[person]
			choice := -1
			for list_position < n {
				candidate := preferences[person * PREFERENCE_STRIDE + list_position]
				list_position += 1
				if candidate == person do return false
				if ranking[candidate * MAX_N + person] <= rightmost[candidate] {
					choice = candidate
					break
				}
			}
			if choice < 0 do return false
			second[person] = list_position - 1
			next_person := preferences[choice * PREFERENCE_STRIDE + rightmost[choice]]
			if visited[next_person] {
				repeated_person = next_person
				break
			}
			person = next_person
		}

		last_in_cycle := position - 1
		tail = visited
		cycle_start := position
		for cycle_start > 0 {
			cycle_start -= 1
			member := cycle[cycle_start]
			tail[member] = false
			if member == repeated_person {
				first_in_cycle = cycle_start
				break
			}
		}
		if cycle_start == 0 && cycle[cycle_start] != repeated_person do return false

		for index := first_in_cycle; index <= last_in_cycle; index += 1 {
			cycle_person := cycle[index]
			leftmost[cycle_person] = second[cycle_person]
			second[cycle_person] = leftmost[cycle_person] + 1
			if leftmost[cycle_person] >= n do return false
			next_choice_in_cycle := preferences[cycle_person * PREFERENCE_STRIDE + leftmost[cycle_person]]
			rightmost[next_choice_in_cycle] = ranking[next_choice_in_cycle * MAX_N + cycle_person]
		}
		for index := first_in_cycle; index <= last_in_cycle; index += 1 {
			cycle_person := cycle[index]
			if leftmost[cycle_person] > rightmost[cycle_person] do return false
		}
	}
}

@(export)
stable_roommates :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_arg := input[0]
	if n_arg < 2 || n_arg > MAX_N || n_arg % 2 != 0 do return -1
	n := int(n_arg)
	if length != c.size_t(1 + n * (n - 1)) do return -1

	var preferences: [MAX_N * PREFERENCE_STRIDE]int
	var ranking: [MAX_N * MAX_N]int
	cursor := 1
	for person := 0; person < n; person += 1 {
		var seen: [MAX_N]bool
		for rank := 0; rank < n - 1; rank += 1 {
			choice_arg := input[cursor]
			cursor += 1
			if choice_arg < 0 || choice_arg >= n_arg || choice_arg == i64(person) do return -1
			choice := int(choice_arg)
			if seen[choice] do return -1
			seen[choice] = true
			preferences[person * PREFERENCE_STRIDE + rank] = choice
			ranking[person * MAX_N + choice] = rank
		}
		preferences[person * PREFERENCE_STRIDE + n - 1] = person
		ranking[person * MAX_N + person] = n - 1
	}
	if has_stable_roommates(n, preferences, ranking) do return 1
	return 0
}
