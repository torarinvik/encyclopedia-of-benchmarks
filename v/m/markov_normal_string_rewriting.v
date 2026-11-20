const max_rules = 8
const max_steps = 32
const max_word = 64
const max_input = 204

@[export: 'markov_normal_string_rewriting']
pub fn markov_normal_string_rewriting(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		if input[0] < 0 || input[0] > max_rules || input[1] < 0 || input[1] > max_steps || input[2] < 0 || input[2] > 48 { return -1 }
		count := int(input[0])
		budget := int(input[1])
		mut word_len := int(input[2])
		if int(length) < 3 + word_len { return -1 }
		mut word := [max_word]i64{}
		mut cursor := 3
		for i in 0 .. word_len {
			if input[cursor] < 0 || input[cursor] > 25 { return -1 }
			word[i] = input[cursor]
			cursor++
		}
		mut kinds := [max_rules]i64{}
		mut lhs_lens := [max_rules]int{}
		mut rhs_lens := [max_rules]int{}
		mut lhs := [max_rules * 8]i64{}
		mut rhs := [max_rules * 8]i64{}
		for r in 0 .. count {
			if cursor + 3 > int(length) { return -1 }
			kind := input[cursor]
			left := input[cursor + 1]
			right := input[cursor + 2]
			cursor += 3
			if (kind != 0 && kind != 1) || left < 1 || left > 8 || right < 0 || right > 8 { return -1 }
			lhs_lens[r] = int(left)
			rhs_lens[r] = int(right)
			kinds[r] = kind
			if cursor + lhs_lens[r] + rhs_lens[r] > int(length) { return -1 }
			for j in 0 .. lhs_lens[r] {
				if input[cursor] < 0 || input[cursor] > 25 { return -1 }
				lhs[r * 8 + j] = input[cursor]
				cursor++
			}
			for j in 0 .. rhs_lens[r] {
				if input[cursor] < 0 || input[cursor] > 25 { return -1 }
				rhs[r * 8 + j] = input[cursor]
				cursor++
			}
		}
		if cursor != int(length) { return -1 }

		mut rewrites := 0
		mut halt := u8(0)
		for {
			mut chosen := count
			mut offset := 0
			for r in 0 .. count {
				if chosen != count { break }
				if lhs_lens[r] > word_len { continue }
				for at in 0 .. word_len - lhs_lens[r] + 1 {
					mut same := true
					for j in 0 .. lhs_lens[r] {
						if word[at + j] != lhs[r * 8 + j] { same = false; break }
					}
					if same { chosen = r; offset = at; break }
				}
			}
			if chosen == count { halt = 0; break }
			if rewrites == budget { halt = 2; break }
			new_len := word_len - lhs_lens[chosen] + rhs_lens[chosen]
			if new_len > max_word { return -3 }
			mut next := [max_word]i64{}
			mut out := 0
			for i in 0 .. offset { next[out] = word[i]; out++ }
			for i in 0 .. rhs_lens[chosen] { next[out] = rhs[chosen * 8 + i]; out++ }
			for i in offset + lhs_lens[chosen] .. word_len { next[out] = word[i]; out++ }
			word = next
			word_len = new_len
			rewrites++
			if kinds[chosen] == 1 { halt = 1; break }
		}
		required := 3 + word_len
		if output == nil || int(capacity) < required { return -2 }
		output[0] = halt
		output[1] = u8(rewrites)
		output[2] = u8(word_len)
		for i in 0 .. word_len { output[3 + i] = u8(word[i]) }
		return i64(required)
	}
}
