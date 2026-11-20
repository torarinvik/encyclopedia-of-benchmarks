module stable_roommates

const max_n = 8
const max_input_length = 58
const preference_stride = max_n + 1

fn has_stable_roommates(n int, preferences [max_n * preference_stride]int, ranking [max_n * max_n]int) bool {
	mut leftmost := [max_n]int{}
	mut rightmost := [max_n]int{}
	mut proposed_to := [max_n]bool{}
	for person in 0 .. n {
		leftmost[person] = 0
		rightmost[person] = n - 1
	}

	mut proposer := 0
	mut next_choice := 0
	for start in 0 .. n {
		proposer = start
		mut steps := 0
		for {
			if leftmost[proposer] > rightmost[proposer] || leftmost[proposer] >= n {
				return false
			}
			next_choice = preferences[proposer * preference_stride + leftmost[proposer]]
			if next_choice == proposer {
				return false
			}
			mut current := preferences[next_choice * preference_stride + rightmost[next_choice]]
			for ranking[next_choice * max_n + proposer] > ranking[next_choice * max_n + current] {
				leftmost[proposer]++
				if leftmost[proposer] > rightmost[proposer] || leftmost[proposer] >= n {
					return false
				}
				next_choice = preferences[proposer * preference_stride + leftmost[proposer]]
				if next_choice == proposer {
					return false
				}
				current = preferences[next_choice * preference_stride + rightmost[next_choice]]
			}
			rightmost[next_choice] = ranking[next_choice * max_n + proposer]
			proposer = current
			if !proposed_to[next_choice] {
				proposed_to[next_choice] = true
				break
			}
			steps++
			if steps > n * n {
				return false
			}
		}
	}
	if proposer != next_choice {
		return false
	}
	for person in 0 .. n {
		if leftmost[person] > rightmost[person] {
			return false
		}
	}

	mut second := [max_n]int{}
	for person in 0 .. n {
		second[person] = leftmost[person] + 1
	}
	mut first_unmatched := 0
	mut first_in_cycle := 0
	mut tail := [max_n]bool{}
	mut cycle := [max_n + 1]int{}
	for {
		for first_unmatched < n && leftmost[first_unmatched] == rightmost[first_unmatched] {
			first_unmatched++
		}
		if first_unmatched >= n {
			for person in 0 .. n {
				partner := preferences[person * preference_stride + leftmost[person]]
				if partner == person || preferences[partner * preference_stride + leftmost[partner]] != person {
					return false
				}
			}
			return true
		}

		mut visited := [max_n]bool{}
		mut person := 0
		mut position := 0
		if first_in_cycle > 0 {
			visited = tail
			person = cycle[first_in_cycle - 1]
			position = first_in_cycle - 1
		} else {
			person = first_unmatched
		}

		mut repeated_person := -1
		for {
			if position >= max_n + 1 {
				return false
			}
			cycle[position] = person
			position++
			visited[person] = true

			mut list_position := second[person]
			mut choice := -1
			for list_position < n {
				candidate := preferences[person * preference_stride + list_position]
				list_position++
				if candidate == person {
					return false
				}
				if ranking[candidate * max_n + person] <= rightmost[candidate] {
					choice = candidate
					break
				}
			}
			if choice < 0 {
				return false
			}
			second[person] = list_position - 1
			next_person := preferences[choice * preference_stride + rightmost[choice]]
			if visited[next_person] {
				repeated_person = next_person
				break
			}
			person = next_person
		}

		last_in_cycle := position - 1
		tail = visited
		mut cycle_start := position
		for cycle_start > 0 {
			cycle_start--
			member := cycle[cycle_start]
			tail[member] = false
			if member == repeated_person {
				first_in_cycle = cycle_start
				break
			}
		}
		if cycle_start == 0 && cycle[cycle_start] != repeated_person {
			return false
		}

		for index in first_in_cycle .. last_in_cycle + 1 {
			cycle_person := cycle[index]
			leftmost[cycle_person] = second[cycle_person]
			second[cycle_person] = leftmost[cycle_person] + 1
			if leftmost[cycle_person] >= n {
				return false
			}
			next_choice_in_cycle := preferences[cycle_person * preference_stride + leftmost[cycle_person]]
			rightmost[next_choice_in_cycle] = ranking[next_choice_in_cycle * max_n + cycle_person]
		}
		for index in first_in_cycle .. last_in_cycle + 1 {
			cycle_person := cycle[index]
			if leftmost[cycle_person] > rightmost[cycle_person] {
				return false
			}
		}
	}
}

@[export: 'stable_roommates']
pub fn stable_roommates(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length {
			return -1
		}
		n_arg := input[0]
		if n_arg < 2 || n_arg > i64(max_n) || n_arg % 2 != 0 {
			return -1
		}
		n := int(n_arg)
		if length != usize(1 + n * (n - 1)) {
			return -1
		}

		mut preferences := [max_n * preference_stride]int{}
		mut ranking := [max_n * max_n]int{}
		mut cursor := 1
		for person in 0 .. n {
			mut seen := [max_n]bool{}
			for rank in 0 .. n - 1 {
				choice_arg := input[cursor]
				cursor++
				if choice_arg < 0 || choice_arg >= n_arg || choice_arg == i64(person) {
					return -1
				}
				choice := int(choice_arg)
				if seen[choice] {
					return -1
				}
				seen[choice] = true
				preferences[person * preference_stride + rank] = choice
				ranking[person * max_n + choice] = rank
			}
			preferences[person * preference_stride + n - 1] = person
			ranking[person * max_n + person] = n - 1
		}
		if has_stable_roommates(n, preferences, ranking) {
			return 1
		}
		return 0
	}
}
