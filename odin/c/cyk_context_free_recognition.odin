package cyk_context_free_recognition

import "core:c"

MAX_NONTERMINALS :: 4
MAX_TERMINALS :: 2
MAX_WORD_LENGTH :: 8
MAX_PRODUCTIONS :: 12
MAX_INPUT_LENGTH :: c.size_t(62)

@(export)
cyk_context_free_recognition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT_LENGTH do return -1
	variables_value := input[0]
	alphabet_value := input[1]
	word_value := input[2]
	rule_value := input[3]
	start_value := input[4]
	if variables_value < 1 || variables_value > MAX_NONTERMINALS ||
		alphabet_value < 1 || alphabet_value > MAX_TERMINALS ||
		word_value < 1 || word_value > MAX_WORD_LENGTH ||
		rule_value < 0 || rule_value > MAX_PRODUCTIONS ||
		start_value < 0 || start_value >= variables_value do return -1
	word_length := int(word_value)
	rule_count := int(rule_value)
	if length != c.size_t(5 + word_length + 4 * rule_count) do return -1
	for position := 0; position < word_length; position += 1 {
		token := input[5 + position]
		if token < 0 || token >= alphabet_value do return -1
	}
	rules := 5 + word_length
	for rule := 0; rule < rule_count; rule += 1 {
		offset := rules + 4 * rule
		kind := input[offset]
		lhs := input[offset + 1]
		first := input[offset + 2]
		second := input[offset + 3]
		if lhs < 0 || lhs >= variables_value do return -1
		if kind == 0 {
			if first < 0 || first >= alphabet_value || second != 0 do return -1
		} else if kind == 1 {
			if first < 0 || first >= variables_value || second < 0 || second >= variables_value do return -1
		} else {
			return -1
		}
	}

	chart: [4 * 8 * 9]bool
	for position := 0; position < word_length; position += 1 {
		token := input[5 + position]
		for rule := 0; rule < rule_count; rule += 1 {
			offset := rules + 4 * rule
			if input[offset] == 0 && input[offset + 2] == token {
				chart[int(input[offset + 1]) * 72 + position * 9 + 1] = true
			}
		}
	}
	for width := 2; width <= word_length; width += 1 {
		for left := 0; left + width <= word_length; left += 1 {
			for rule := 0; rule < rule_count; rule += 1 {
				offset := rules + 4 * rule
				if input[offset] != 1 do continue
				lhs := int(input[offset + 1])
				first := int(input[offset + 2])
				second := int(input[offset + 3])
				for split := 1; split < width; split += 1 {
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
	if chart[int(start_value) * 72 + word_length] do return 1
	return 0
}
