module penney_game_pattern_probability

const modulus = i64(998244353)
const max_states = 7

fn pow_mod(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn find_state(codes [max_states]i64, lengths [max_states]int, count int, code i64, length int) int {
	for index in 0 .. count {
		if codes[index] == code && lengths[index] == length { return index }
	}
	return -1
}

fn solve(word_length int, first i64, second i64) i64 {
	mut codes := [max_states]i64{}
	mut lengths := [max_states]int{}
	mut state_count := 1
	for prefix_length in 1 .. word_length {
		for which in 0 .. 2 {
			pattern := if which == 0 { first } else { second }
			code := pattern >> (word_length - prefix_length)
			if find_state(codes, lengths, state_count, code, prefix_length) < 0 {
				codes[state_count] = code
				lengths[state_count] = prefix_length
				state_count++
			}
		}
	}

	mut matrix := [max_states][max_states + 1]i64{}
	for row in 0 .. state_count {
		for column in 0 .. state_count {
			matrix[row][column] = if row == column { 2 } else { 0 }
		}
		for bit in 0 .. 2 {
			candidate := (codes[row] << 1) | i64(bit)
			candidate_length := lengths[row] + 1
			if candidate_length == word_length && candidate == first {
				matrix[row][state_count]++
				continue
			}
			if candidate_length == word_length && candidate == second { continue }

			mut suffix_length := candidate_length
			if suffix_length > word_length - 1 { suffix_length = word_length - 1 }
			mut destination := -1
			for suffix_length >= 0 && destination < 0 {
				suffix_mask := (i64(1) << suffix_length) - 1
				destination = find_state(codes, lengths, state_count,
					candidate & suffix_mask, suffix_length)
				suffix_length--
			}
			if destination < 0 { destination = 0 }
			matrix[row][destination] = (matrix[row][destination] - 1 + modulus) % modulus
		}
	}

	for column in 0 .. state_count {
		mut pivot := column
		for pivot < state_count && matrix[pivot][column] == 0 { pivot++ }
		if pivot == state_count { return -1 }
		if pivot != column {
			for j in 0 .. state_count + 1 {
				temporary := matrix[column][j]
				matrix[column][j] = matrix[pivot][j]
				matrix[pivot][j] = temporary
			}
		}
		inverse := pow_mod(matrix[column][column], modulus - 2)
		for j in column .. state_count + 1 {
			matrix[column][j] = matrix[column][j] * inverse % modulus
		}
		for row in 0 .. state_count {
			if row == column { continue }
			factor := matrix[row][column]
			for j in column .. state_count + 1 {
				product := factor * matrix[column][j] % modulus
				matrix[row][j] = (matrix[row][j] - product + modulus) % modulus
			}
		}
	}
	return matrix[0][state_count]
}

@[export: 'penney_game_pattern_probability']
pub fn penney_game_pattern_probability(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		word_length := input[0]
		if word_length < 1 || word_length > 4 { return -1 }
		limit := i64(1) << word_length
		first := input[1]
		second := input[2]
		if first < 0 || second < 0 || first >= limit || second >= limit || first == second {
			return -1
		}
		return solve(int(word_length), first, second)
	}
}
