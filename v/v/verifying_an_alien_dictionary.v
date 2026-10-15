module verifying_an_alien_dictionary

@[export: 'verifying_an_alien_dictionary']
pub fn verifying_an_alien_dictionary(input &i64, length usize) i64 {
	if length < 27 || length > 2127 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 100 { return -1 }
		word_count := int(input[0])
		mut rank := [26]i64{}
		mut order_seen := [26]bool{}
		for position in 0 .. 26 {
			letter := input[1 + position]
			if letter < i64('a') || letter > i64('z') { return -1 }
			index := int(letter - i64('a'))
			if order_seen[index] { return -1 }
			order_seen[index] = true
			rank[index] = i64(position)
		}
		mut starts := [100]int{}
		mut word_lengths := [100]int{}
		mut offset := 27
		for word in 0 .. word_count {
			if offset >= int(length) || input[offset] < 1 || input[offset] > 20 { return -1 }
			word_length := int(input[offset])
			offset++
			if word_length > int(length) - offset { return -1 }
			starts[word] = offset
			word_lengths[word] = word_length
			for character in 0 .. word_length {
				letter := input[offset + character]
				if letter < i64('a') || letter > i64('z') { return -1 }
			}
			offset += word_length
		}
		if offset != int(length) { return -1 }
		for word in 0 .. word_count - 1 {
			left_length := word_lengths[word]
			right_length := word_lengths[word + 1]
			mut limit := left_length
			if right_length < limit { limit = right_length }
			mut decided := false
			for character in 0 .. limit {
				left_letter := int(input[starts[word] + character] - i64('a'))
				right_letter := int(input[starts[word + 1] + character] - i64('a'))
				if rank[left_letter] < rank[right_letter] {
					decided = true
					break
				}
				if rank[left_letter] > rank[right_letter] { return 0 }
			}
			if !decided && left_length > right_length { return 0 }
		}
		return 1
	}
}
