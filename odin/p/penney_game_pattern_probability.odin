package penney_game_pattern_probability

import "core:c"

MODULUS :: i64(998244353)
MAX_STATES :: 7

pow_mod :: proc(base_value, exponent_value: i64) -> i64 {
	base := base_value
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % MODULUS }
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

find_state :: proc(codes: [MAX_STATES]i64, lengths: [MAX_STATES]i64,
				   count: int, code, length: i64) -> int {
	for index := 0; index < count; index += 1 {
		if codes[index] == code && lengths[index] == length { return index }
	}
	return -1
}

solve :: proc(word_length, first, second: i64) -> i64 {
	codes: [MAX_STATES]i64
	lengths: [MAX_STATES]i64
	state_count := 1
	for prefix_length := i64(1); prefix_length < word_length; prefix_length += 1 {
		for which := 0; which < 2; which += 1 {
			pattern := first
			if which == 1 { pattern = second }
			code := pattern >> (word_length - prefix_length)
			if find_state(codes, lengths, state_count, code, prefix_length) < 0 {
				codes[state_count] = code
				lengths[state_count] = prefix_length
				state_count += 1
			}
		}
	}

	matrix: [MAX_STATES][MAX_STATES + 1]i64
	for row := 0; row < state_count; row += 1 {
		for column := 0; column <= state_count; column += 1 {
			matrix[row][column] = 0
		}
		for column := 0; column < state_count; column += 1 {
			if row == column { matrix[row][column] = 2 }
		}
		for bit := i64(0); bit <= 1; bit += 1 {
			candidate := (codes[row] << 1) | bit
			candidate_length := lengths[row] + 1
			if candidate_length == word_length && candidate == first {
				matrix[row][state_count] += 1
				continue
			}
			if candidate_length == word_length && candidate == second { continue }

			suffix_length := candidate_length
			if suffix_length > word_length - 1 { suffix_length = word_length - 1 }
			destination := -1
			for suffix_length >= 0 && destination < 0 {
				suffix_mask := (i64(1) << suffix_length) - 1
				destination = find_state(codes, lengths, state_count,
					candidate & suffix_mask, suffix_length)
				suffix_length -= 1
			}
			if destination < 0 { destination = 0 }
			matrix[row][destination] = (matrix[row][destination] - 1 + MODULUS) % MODULUS
		}
	}

	for column := 0; column < state_count; column += 1 {
		pivot := column
		for pivot < state_count && matrix[pivot][column] == 0 { pivot += 1 }
		if pivot == state_count { return -1 }
		if pivot != column {
			for j := 0; j <= state_count; j += 1 {
				temporary := matrix[column][j]
				matrix[column][j] = matrix[pivot][j]
				matrix[pivot][j] = temporary
			}
		}
		inverse := pow_mod(matrix[column][column], MODULUS - 2)
		for j := column; j <= state_count; j += 1 {
			matrix[column][j] = matrix[column][j] * inverse % MODULUS
		}
		for row := 0; row < state_count; row += 1 {
			if row == column { continue }
			factor := matrix[row][column]
			for j := column; j <= state_count; j += 1 {
				product := factor * matrix[column][j] % MODULUS
				matrix[row][j] = (matrix[row][j] - product + MODULUS) % MODULUS
			}
		}
	}
	return matrix[0][state_count]
}

@(export, link_name="penney_game_pattern_probability")
penney_game_pattern_probability :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	word_length := input[0]
	if word_length < 1 || word_length > 4 do return -1
	limit := i64(1) << word_length
	first, second := input[1], input[2]
	if first < 0 || second < 0 || first >= limit || second >= limit || first == second do return -1
	return solve(word_length, first, second)
}
