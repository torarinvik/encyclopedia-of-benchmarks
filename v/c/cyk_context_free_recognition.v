module cyk_context_free_recognition

const max_nonterminals = 4
const max_terminals = 2
const max_word_length = 8
const max_productions = 12
const max_input_length = usize(62)

@[export: 'cyk_context_free_recognition']
pub fn cyk_context_free_recognition(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input_length { return -1 }
		variables_value := input[0]
		alphabet_value := input[1]
		word_value := input[2]
		rule_value := input[3]
		start_value := input[4]
		if variables_value < 1 || variables_value > max_nonterminals ||
			alphabet_value < 1 || alphabet_value > max_terminals ||
			word_value < 1 || word_value > max_word_length ||
			rule_value < 0 || rule_value > max_productions ||
			start_value < 0 || start_value >= variables_value { return -1 }
		word_length := int(word_value)
		rule_count := int(rule_value)
		if length != usize(5 + word_length + 4 * rule_count) { return -1 }
		for position in 0 .. word_length {
			token := input[5 + position]
			if token < 0 || token >= alphabet_value { return -1 }
		}
		rules := 5 + word_length
		for rule in 0 .. rule_count {
			offset := rules + 4 * rule
			kind := input[offset]
			lhs := input[offset + 1]
			first := input[offset + 2]
			second := input[offset + 3]
			if lhs < 0 || lhs >= variables_value { return -1 }
			if kind == 0 {
				if first < 0 || first >= alphabet_value || second != 0 { return -1 }
			} else if kind == 1 {
				if first < 0 || first >= variables_value || second < 0 || second >= variables_value { return -1 }
			} else { return -1 }
		}
		mut chart := [4 * 8 * 9]bool{}
		for position in 0 .. word_length {
			token := input[5 + position]
			for rule in 0 .. rule_count {
				offset := rules + 4 * rule
				if input[offset] == 0 && input[offset + 2] == token {
					chart[int(input[offset + 1]) * 72 + position * 9 + 1] = true
				}
			}
		}
		for width in 2 .. (word_length + 1) {
			for left in 0 .. (word_length - width + 1) {
				for rule in 0 .. rule_count {
					offset := rules + 4 * rule
					if input[offset] != 1 { continue }
					lhs := int(input[offset + 1])
					first := int(input[offset + 2])
					second := int(input[offset + 3])
					for split in 1 .. width {
						left_cell := first * 72 + left * 9 + split
						right_cell := second * 72 + (left + split) * 9 + width - split
						if chart[left_cell] && chart[right_cell] {
							chart[lhs * 72 + left * 9 + width] = true
							break
						}
					}
				}
			}
		}
		if chart[int(start_value) * 72 + word_length] { return 1 }
		return 0
	}
}
