module round_robin_tournament_schedule

const max_teams = 8
const max_parseable_input = 2
const max_cells = 64

@[export: 'round_robin_tournament_schedule']
pub fn round_robin_tournament_schedule(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_parseable_input {
		return -1
	}
	if length != 1 {
		return -1
	}
	n_word := input[0]
	if n_word < 2 || n_word > max_teams {
		return -1
	}

	n := int(n_word)
	padded := n + (n & 1)
	ring_size := padded - 1
	rounds := ring_size
	fixed := padded - 1
	mut table := [max_cells]u8{}
	for i in 0 .. max_cells {
		table[i] = 255
	}

	for round in 0 .. rounds {
		if fixed < n {
			table[fixed * rounds + round] = u8(round)
			table[round * rounds + round] = u8(fixed)
		}
		for offset in 1 .. (padded / 2) {
			left := (round + offset) % ring_size
			right := (round + ring_size - offset) % ring_size
			if left < n && right < n {
				table[left * rounds + round] = u8(right)
				table[right * rounds + round] = u8(left)
			}
		}
	}

	required := 2 + n * rounds
	if output == nil || capacity < usize(required) {
		return -2
	}
	output[0] = u8(n)
	output[1] = u8(rounds)
	for i in 0 .. (n * rounds) {
		output[i + 2] = table[i]
	}
	return i64(required)
}
